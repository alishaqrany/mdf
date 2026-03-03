<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class record_daily_login extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'User ID (0 = current user)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $userid = 0): array {
        global $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['userid' => $userid]);
        $userid = $params['userid'] ?: (int)$USER->id;

        $context = \context_system::instance();
        self::validate_context($context);

        // Record the daily login and get streak info.
        $streakInfo = \local_mdf_api\gamification_helper::record_daily_login($userid);

        // Return updated full profile.
        return \local_mdf_api\gamification_helper::get_user_profile($userid);
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'userid'            => new external_value(PARAM_INT, 'User ID'),
            'fullname'          => new external_value(PARAM_TEXT, 'Full name'),
            'profileimageurl'   => new external_value(PARAM_URL, 'Profile image URL', VALUE_OPTIONAL),
            'totalpoints'       => new external_value(PARAM_INT, 'Total points'),
            'level'             => new external_value(PARAM_INT, 'Current level'),
            'currentlevelpoints' => new external_value(PARAM_INT, 'Points in current level'),
            'nextlevelpoints'   => new external_value(PARAM_INT, 'Points needed for next level'),
            'currentstreak'     => new external_value(PARAM_INT, 'Current daily streak'),
            'longeststreak'     => new external_value(PARAM_INT, 'Longest streak ever'),
            'lastactivitydate'  => new external_value(PARAM_INT, 'Last activity timestamp'),
            'rank'              => new external_value(PARAM_INT, 'Global rank'),
            'totalusers'        => new external_value(PARAM_INT, 'Total users with points'),
        ]);
    }
}
