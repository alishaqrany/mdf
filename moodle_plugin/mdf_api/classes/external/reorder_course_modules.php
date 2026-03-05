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
 * Move a course module to a different section or position.
 *
 * @package    local_mdf_api
 */
class reorder_course_modules extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cmid'      => new external_value(PARAM_INT, 'Course module ID to move'),
            'sectionid' => new external_value(PARAM_INT, 'Target section ID'),
            'beforemod' => new external_value(PARAM_INT, 'Place before this module ID (0 = end)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $cmid, int $sectionid, int $beforemod = 0): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'cmid'      => $cmid,
            'sectionid' => $sectionid,
            'beforemod' => $beforemod,
        ]);

        $cm = get_coursemodule_from_id('', $params['cmid'], 0, false, MUST_EXIST);
        $context = \context_course::instance($cm->course);
        self::validate_context($context);
        require_capability('moodle/course:manageactivities', $context);

        $targetsection = $DB->get_record('course_sections', [
            'id' => $params['sectionid'],
        ], '*', MUST_EXIST);

        moveto_module($cm, $targetsection, $params['beforemod'] > 0
            ? get_coursemodule_from_id('', $params['beforemod'])
            : null);

        return [
            'success' => true,
            'message' => 'Module moved successfully',
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether the operation succeeded'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
