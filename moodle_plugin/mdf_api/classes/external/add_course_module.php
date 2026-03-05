<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once($CFG->dirroot . '/course/lib.php');
require_once($CFG->dirroot . '/course/modlib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Add a new activity or resource module to a course section.
 *
 * Supported module types: resource, page, label, assign, quiz, forum, url, folder.
 *
 * @package    local_mdf_api
 */
class add_course_module extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'courseid'   => new external_value(PARAM_INT, 'Course ID'),
            'section'    => new external_value(PARAM_INT, 'Section number (0-based)'),
            'moduletype' => new external_value(PARAM_ALPHANUMEXT, 'Module type: resource, page, label, assign, quiz, forum, url, folder'),
            'name'       => new external_value(PARAM_TEXT, 'Activity name'),
            'description'=> new external_value(PARAM_RAW, 'Description/intro (HTML)', VALUE_DEFAULT, ''),
            'visible'    => new external_value(PARAM_INT, 'Visibility (0/1)', VALUE_DEFAULT, 1),
            'config'     => new external_value(PARAM_RAW, 'JSON with type-specific settings', VALUE_DEFAULT, '{}'),
        ]);
    }

    public static function execute(
        int $courseid,
        int $section,
        string $moduletype,
        string $name,
        string $description = '',
        int $visible = 1,
        string $config = '{}'
    ): array {
        global $DB, $CFG;

        $params = self::validate_parameters(self::execute_parameters(), [
            'courseid'    => $courseid,
            'section'     => $section,
            'moduletype'  => $moduletype,
            'name'        => $name,
            'description' => $description,
            'visible'     => $visible,
            'config'      => $config,
        ]);

        $context = \context_course::instance($params['courseid']);
        self::validate_context($context);
        require_capability('moodle/course:manageactivities', $context);

        $course = get_course($params['courseid']);
        $modulename = $params['moduletype'];

        // Validate module type exists.
        $module = $DB->get_record('modules', ['name' => $modulename, 'visible' => 1]);
        if (!$module) {
            throw new \invalid_parameter_exception("Unknown or disabled module type: $modulename");
        }

        $extra = json_decode($params['config'], true) ?? [];

        // Build the module info object used by add_moduleinfo().
        $moduleinfo = new \stdClass();
        $moduleinfo->modulename = $modulename;
        $moduleinfo->module = $module->id;
        $moduleinfo->name = $params['name'];
        $moduleinfo->intro = $params['description'];
        $moduleinfo->introformat = FORMAT_HTML;
        $moduleinfo->section = $params['section'];
        $moduleinfo->visible = $params['visible'];
        $moduleinfo->visibleoncoursepage = 1;
        $moduleinfo->course = $course->id;
        $moduleinfo->coursemodule = 0; // New.
        $moduleinfo->cmidnumber = '';
        $moduleinfo->groupmode = 0;
        $moduleinfo->groupingid = 0;
        $moduleinfo->availability = null;
        $moduleinfo->completion = 0;

        // Type-specific defaults.
        switch ($modulename) {
            case 'assign':
                $moduleinfo->alwaysshowdescription = 1;
                $moduleinfo->nosubmissions = 0;
                $moduleinfo->submissiondrafts = 0;
                $moduleinfo->sendnotifications = 0;
                $moduleinfo->sendlatenotifications = 0;
                $moduleinfo->sendstudentnotifications = 1;
                $moduleinfo->duedate = $extra['duedate'] ?? 0;
                $moduleinfo->cutoffdate = $extra['cutoffdate'] ?? 0;
                $moduleinfo->gradingduedate = $extra['gradingduedate'] ?? 0;
                $moduleinfo->allowsubmissionsfromdate = $extra['allowsubmissionsfromdate'] ?? 0;
                $moduleinfo->grade = $extra['maxgrade'] ?? 100;
                $moduleinfo->teamsubmission = 0;
                $moduleinfo->requireallteammemberssubmit = 0;
                $moduleinfo->blindmarking = 0;
                $moduleinfo->markingworkflow = 0;
                $moduleinfo->markingallocation = 0;
                // Submission types.
                $moduleinfo->assignsubmission_onlinetext_enabled = ($extra['onlinetext'] ?? true) ? 1 : 0;
                $moduleinfo->assignsubmission_file_enabled = ($extra['filesubmission'] ?? true) ? 1 : 0;
                $moduleinfo->assignsubmission_file_maxfiles = $extra['maxfiles'] ?? 5;
                $moduleinfo->assignsubmission_file_maxsizebytes = $extra['maxsizebytes'] ?? 0;
                $moduleinfo->assignfeedback_comments_enabled = 1;
                $moduleinfo->assignfeedback_file_enabled = 0;
                $moduleinfo->assignfeedback_offline_enabled = 0;
                break;

            case 'quiz':
                $moduleinfo->timeopen = $extra['timeopen'] ?? 0;
                $moduleinfo->timeclose = $extra['timeclose'] ?? 0;
                $moduleinfo->timelimit = $extra['timelimit'] ?? 0;
                $moduleinfo->grade = $extra['maxgrade'] ?? 10;
                $moduleinfo->attempts = $extra['attempts'] ?? 0; // 0 = unlimited
                $moduleinfo->grademethod = $extra['grademethod'] ?? 1; // 1 = highest
                $moduleinfo->questionsperpage = $extra['questionsperpage'] ?? 1;
                $moduleinfo->shuffleanswers = $extra['shuffleanswers'] ?? 1;
                $moduleinfo->preferredbehaviour = $extra['behaviour'] ?? 'deferredfeedback';
                $moduleinfo->navmethod = 'free';
                $moduleinfo->overduehandling = $extra['overduehandling'] ?? 'autosubmit';
                $moduleinfo->quizpassword = $extra['password'] ?? '';
                break;

            case 'forum':
                $moduleinfo->type = $extra['forumtype'] ?? 'general';
                $moduleinfo->forcesubscribe = $extra['forcesubscribe'] ?? 0;
                $moduleinfo->maxbytes = $extra['maxbytes'] ?? 0;
                $moduleinfo->maxattachments = $extra['maxattachments'] ?? 9;
                $moduleinfo->blockafter = 0;
                $moduleinfo->blockperiod = 0;
                $moduleinfo->warnafter = 0;
                $moduleinfo->displaywordcount = 0;
                break;

            case 'page':
                $moduleinfo->content = $extra['content'] ?? '';
                $moduleinfo->contentformat = FORMAT_HTML;
                $moduleinfo->display = $extra['display'] ?? 5; // 5 = open
                $moduleinfo->printintro = $extra['printintro'] ?? 1;
                $moduleinfo->printlastmodified = $extra['printlastmodified'] ?? 1;
                break;

            case 'label':
                // Label uses intro as its content.
                $moduleinfo->name = !empty($params['name']) ? $params['name'] : 'Label';
                break;

            case 'url':
                $moduleinfo->externalurl = $extra['url'] ?? '';
                $moduleinfo->display = $extra['display'] ?? 0;
                if (empty($moduleinfo->externalurl)) {
                    throw new \invalid_parameter_exception('URL is required for url module type');
                }
                break;

            case 'resource':
                // Resource requires a file — the file should be uploaded first via
                // core_files_upload, then the draft itemid passed in config.
                $moduleinfo->files = $extra['draftitemid'] ?? 0;
                $moduleinfo->display = $extra['display'] ?? 0;
                $moduleinfo->showsize = $extra['showsize'] ?? 1;
                $moduleinfo->showtype = $extra['showtype'] ?? 1;
                break;

            case 'folder':
                $moduleinfo->files = $extra['draftitemid'] ?? 0;
                $moduleinfo->display = $extra['display'] ?? 0;
                $moduleinfo->showdownloadfolder = $extra['showdownloadfolder'] ?? 1;
                $moduleinfo->showexpanded = $extra['showexpanded'] ?? 1;
                break;
        }

        $result = add_moduleinfo($moduleinfo, $course);

        return [
            'success' => true,
            'cmid'    => (int)$result->coursemodule,
            'message' => "Module '$modulename' added successfully",
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether the operation succeeded'),
            'cmid'    => new external_value(PARAM_INT, 'New course module ID'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
