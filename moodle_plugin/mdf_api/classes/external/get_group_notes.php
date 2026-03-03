<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_group_notes extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'groupid' => new external_value(PARAM_INT, 'Group ID'),
        ]);
    }

    public static function execute(int $groupid): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['groupid' => $groupid]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;
        $gid = $params['groupid'];

        // Verify group exists.
        $DB->get_record('local_mdf_study_groups', ['id' => $gid], 'id', MUST_EXIST);

        $sql = "SELECT n.*
                FROM {local_mdf_study_notes} n
                WHERE n.groupid = :groupid
                  AND n.visibility = 'group'
                ORDER BY n.timecreated DESC";

        $records = $DB->get_records_sql($sql, ['groupid' => $gid]);

        $result = [];
        foreach ($records as $n) {
            $result[] = get_course_notes::format_note($n, $userid);
        }

        return $result;
    }

    public static function execute_returns(): external_multiple_structure {
        return new external_multiple_structure(
            get_course_notes::note_structure()
        );
    }
}
