<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once($CFG->dirroot . '/course/lib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Manage course sections — add, edit, delete, move.
 *
 * @package    local_mdf_api
 */
class manage_course_section extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'courseid'  => new external_value(PARAM_INT, 'Course ID'),
            'action'    => new external_value(PARAM_ALPHA, 'Action: add, edit, delete, move'),
            'sectionid' => new external_value(PARAM_INT, 'Section ID (for edit/delete/move)', VALUE_DEFAULT, 0),
            'name'      => new external_value(PARAM_TEXT, 'Section name', VALUE_DEFAULT, ''),
            'summary'   => new external_value(PARAM_RAW, 'Section summary (HTML)', VALUE_DEFAULT, ''),
            'visible'   => new external_value(PARAM_INT, 'Visibility (0/1)', VALUE_DEFAULT, 1),
            'position'  => new external_value(PARAM_INT, 'Target position (for move)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(
        int $courseid,
        string $action,
        int $sectionid = 0,
        string $name = '',
        string $summary = '',
        int $visible = 1,
        int $position = 0
    ): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'courseid'  => $courseid,
            'action'    => $action,
            'sectionid' => $sectionid,
            'name'      => $name,
            'summary'   => $summary,
            'visible'   => $visible,
            'position'  => $position,
        ]);

        $context = \context_course::instance($params['courseid']);
        self::validate_context($context);
        require_capability('moodle/course:update', $context);

        $course = get_course($params['courseid']);

        switch ($params['action']) {
            case 'add':
                // Increase the number of sections by 1.
                $numsections = course_get_format($course)->get_last_section_number();
                course_create_sections_if_missing($course, $numsections + 1);
                $newsection = $DB->get_record('course_sections', [
                    'course' => $course->id,
                    'section' => $numsections + 1,
                ]);
                if ($newsection && !empty($params['name'])) {
                    $newsection->name = $params['name'];
                    $newsection->summary = $params['summary'];
                    $newsection->summaryformat = FORMAT_HTML;
                    $newsection->visible = $params['visible'];
                    $DB->update_record('course_sections', $newsection);
                    rebuild_course_cache($course->id, true);
                }
                return [
                    'success'   => true,
                    'sectionid' => $newsection ? (int)$newsection->id : 0,
                    'message'   => 'Section added',
                ];

            case 'edit':
                $section = $DB->get_record('course_sections', [
                    'id' => $params['sectionid'],
                    'course' => $course->id,
                ], '*', MUST_EXIST);
                if (!empty($params['name'])) {
                    $section->name = $params['name'];
                }
                $section->summary = $params['summary'];
                $section->summaryformat = FORMAT_HTML;
                $section->visible = $params['visible'];
                $DB->update_record('course_sections', $section);
                rebuild_course_cache($course->id, true);
                return [
                    'success'   => true,
                    'sectionid' => (int)$section->id,
                    'message'   => 'Section updated',
                ];

            case 'delete':
                $section = $DB->get_record('course_sections', [
                    'id' => $params['sectionid'],
                    'course' => $course->id,
                ], '*', MUST_EXIST);
                course_delete_section($course, $section, true);
                return [
                    'success'   => true,
                    'sectionid' => (int)$params['sectionid'],
                    'message'   => 'Section deleted',
                ];

            case 'move':
                $section = $DB->get_record('course_sections', [
                    'id' => $params['sectionid'],
                    'course' => $course->id,
                ], '*', MUST_EXIST);
                move_section_to($course, $section->section, $params['position']);
                return [
                    'success'   => true,
                    'sectionid' => (int)$section->id,
                    'message'   => 'Section moved',
                ];

            default:
                throw new \invalid_parameter_exception("Invalid action: {$params['action']}");
        }
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success'   => new external_value(PARAM_BOOL, 'Whether the operation succeeded'),
            'sectionid' => new external_value(PARAM_INT, 'Affected section ID'),
            'message'   => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
