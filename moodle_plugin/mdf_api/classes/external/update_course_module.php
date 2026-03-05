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
 * Update an existing course module's settings.
 *
 * @package    local_mdf_api
 */
class update_course_module extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cmid'        => new external_value(PARAM_INT, 'Course module ID'),
            'name'        => new external_value(PARAM_TEXT, 'Activity name', VALUE_DEFAULT, ''),
            'description' => new external_value(PARAM_RAW, 'Description/intro (HTML)', VALUE_DEFAULT, ''),
            'visible'     => new external_value(PARAM_INT, 'Visibility (0/1, -1 = no change)', VALUE_DEFAULT, -1),
            'config'      => new external_value(PARAM_RAW, 'JSON with type-specific settings', VALUE_DEFAULT, '{}'),
        ]);
    }

    public static function execute(
        int $cmid,
        string $name = '',
        string $description = '',
        int $visible = -1,
        string $config = '{}'
    ): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'cmid'        => $cmid,
            'name'        => $name,
            'description' => $description,
            'visible'     => $visible,
            'config'      => $config,
        ]);

        // Get the course module record.
        $cm = get_coursemodule_from_id('', $params['cmid'], 0, false, MUST_EXIST);
        $context = \context_module::instance($cm->id);
        self::validate_context($context);
        require_capability('moodle/course:manageactivities', \context_course::instance($cm->course));

        $course = get_course($cm->course);
        $modulename = $cm->modname;

        // Get current module info.
        list($cm_current, $context_current, $module_current, $data, $cw) =
            get_moduleinfo_data($cm, $course);

        $extra = json_decode($params['config'], true) ?? [];

        // Update basic fields.
        if (!empty($params['name'])) {
            $data->name = $params['name'];
        }
        if (!empty($params['description'])) {
            $data->intro = $params['description'];
            $data->introformat = FORMAT_HTML;
        }
        if ($params['visible'] >= 0) {
            $data->visible = $params['visible'];
        }

        // Type-specific updates.
        switch ($modulename) {
            case 'assign':
                if (isset($extra['duedate'])) $data->duedate = $extra['duedate'];
                if (isset($extra['cutoffdate'])) $data->cutoffdate = $extra['cutoffdate'];
                if (isset($extra['maxgrade'])) $data->grade = $extra['maxgrade'];
                if (isset($extra['allowsubmissionsfromdate'])) $data->allowsubmissionsfromdate = $extra['allowsubmissionsfromdate'];
                break;

            case 'quiz':
                if (isset($extra['timeopen'])) $data->timeopen = $extra['timeopen'];
                if (isset($extra['timeclose'])) $data->timeclose = $extra['timeclose'];
                if (isset($extra['timelimit'])) $data->timelimit = $extra['timelimit'];
                if (isset($extra['maxgrade'])) $data->grade = $extra['maxgrade'];
                if (isset($extra['attempts'])) $data->attempts = $extra['attempts'];
                break;

            case 'forum':
                if (isset($extra['forumtype'])) $data->type = $extra['forumtype'];
                if (isset($extra['forcesubscribe'])) $data->forcesubscribe = $extra['forcesubscribe'];
                break;

            case 'page':
                if (isset($extra['content'])) {
                    $data->content = $extra['content'];
                    $data->contentformat = FORMAT_HTML;
                }
                break;

            case 'url':
                if (isset($extra['url'])) $data->externalurl = $extra['url'];
                break;
        }

        $data->coursemodule = $cm->id;
        update_moduleinfo($cm, $data, $course);

        return [
            'success' => true,
            'cmid'    => (int)$cm->id,
            'message' => "Module updated successfully",
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether the operation succeeded'),
            'cmid'    => new external_value(PARAM_INT, 'Updated course module ID'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
