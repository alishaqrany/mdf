<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Get AI message limits and current usage for a user.
 */
class get_ai_user_limit extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'User ID (0 = current user)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $userid = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'userid' => $userid,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:useai', $context);

        $uid = $params['userid'] > 0 ? $params['userid'] : $USER->id;

        // Get user-specific limits, else defaults.
        $limit = $DB->get_record('local_mdf_ai_limits', ['userid' => $uid]);
        if (!$limit) {
            $defaults = $DB->get_record('local_mdf_ai_limits', ['userid' => 0]);
            $dailylimit   = $defaults ? (int)$defaults->dailylimit : 50;
            $monthlylimit = $defaults ? (int)$defaults->monthlylimit : 1000;

            return [
                'userid'       => $uid,
                'dailylimit'   => $dailylimit,
                'monthlylimit' => $monthlylimit,
                'dailycount'   => 0,
                'monthlycount' => 0,
                'hasreached'   => false,
            ];
        }

        // Reset counters if stale.
        $today      = strtotime('today');
        $monthstart = strtotime('first day of this month midnight');

        $dailycount   = $limit->lastreset >= $today ? (int)$limit->dailycount : 0;
        $monthlycount = $limit->lastreset >= $monthstart ? (int)$limit->monthlycount : 0;

        $hasreached = ($dailycount >= (int)$limit->dailylimit) ||
                      ($monthlycount >= (int)$limit->monthlylimit);

        return [
            'userid'       => $uid,
            'dailylimit'   => (int)$limit->dailylimit,
            'monthlylimit' => (int)$limit->monthlylimit,
            'dailycount'   => $dailycount,
            'monthlycount' => $monthlycount,
            'hasreached'   => $hasreached,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'userid'       => new external_value(PARAM_INT, 'User ID'),
            'dailylimit'   => new external_value(PARAM_INT, 'Daily limit'),
            'monthlylimit' => new external_value(PARAM_INT, 'Monthly limit'),
            'dailycount'   => new external_value(PARAM_INT, 'Messages sent today'),
            'monthlycount' => new external_value(PARAM_INT, 'Messages sent this month'),
            'hasreached'   => new external_value(PARAM_BOOL, 'Whether limit is reached'),
        ]);
    }
}
