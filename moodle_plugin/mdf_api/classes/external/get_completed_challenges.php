<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_completed_challenges extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'User ID (0 = current)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $userid = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['userid' => $userid]);
        $userid = $params['userid'] ?: (int)$USER->id;

        $context = \context_system::instance();
        self::validate_context($context);

        $sql = "SELECT c.*, uc.currentvalue, uc.status as userstatus, uc.claimedat
                FROM {local_mdf_user_challenges} uc
                JOIN {local_mdf_challenges} c ON c.id = uc.challengeid
                WHERE uc.userid = :userid
                  AND (uc.status = 'completed' OR uc.status = 'claimed')
                ORDER BY uc.timemodified DESC";

        $records = $DB->get_records_sql($sql, ['userid' => $userid]);

        $result = [];
        foreach ($records as $r) {
            $result[] = get_active_challenges::format_challenge($r);
        }

        return ['challenges' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'challenges' => new external_multiple_structure(
                get_active_challenges::challenge_structure()
            ),
        ]);
    }
}
