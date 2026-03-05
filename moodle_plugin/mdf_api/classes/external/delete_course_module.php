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
 * Delete a course module (activity/resource).
 *
 * @package    local_mdf_api
 */
class delete_course_module extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cmid' => new external_value(PARAM_INT, 'Course module ID to delete'),
        ]);
    }

    public static function execute(int $cmid): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'cmid' => $cmid,
        ]);

        $cm = get_coursemodule_from_id('', $params['cmid'], 0, false, MUST_EXIST);
        $context = \context_course::instance($cm->course);
        self::validate_context($context);
        require_capability('moodle/course:manageactivities', $context);

        course_delete_module($cm->id);

        return [
            'success' => true,
            'message' => 'Module deleted successfully',
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether the operation succeeded'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
