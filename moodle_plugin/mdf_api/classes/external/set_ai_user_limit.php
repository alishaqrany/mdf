<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Set AI message limits for a user or defaults (userid=0).
 */
class set_ai_user_limit extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid'       => new external_value(PARAM_INT, 'User ID (0 = default limits)'),
            'dailylimit'   => new external_value(PARAM_INT, 'Daily message limit'),
            'monthlylimit' => new external_value(PARAM_INT, 'Monthly message limit'),
        ]);
    }

    public static function execute(int $userid, int $dailylimit, int $monthlylimit): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'userid' => $userid, 'dailylimit' => $dailylimit, 'monthlylimit' => $monthlylimit,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:manageai', $context);

        $existing = $DB->get_record('local_mdf_ai_limits', ['userid' => $params['userid']]);
        $now = time();

        if ($existing) {
            $existing->dailylimit   = $params['dailylimit'];
            $existing->monthlylimit = $params['monthlylimit'];
            $existing->timemodified = $now;
            $DB->update_record('local_mdf_ai_limits', $existing);
            $id = (int)$existing->id;
        } else {
            $record = new \stdClass();
            $record->userid       = $params['userid'];
            $record->dailylimit   = $params['dailylimit'];
            $record->monthlylimit = $params['monthlylimit'];
            $record->dailycount   = 0;
            $record->monthlycount = 0;
            $record->lastreset    = $now;
            $record->timemodified = $now;
            $id = (int)$DB->insert_record('local_mdf_ai_limits', $record);
        }

        return ['success' => true, 'id' => $id];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether save succeeded'),
            'id'      => new external_value(PARAM_INT, 'Limit record ID'),
        ]);
    }
}
