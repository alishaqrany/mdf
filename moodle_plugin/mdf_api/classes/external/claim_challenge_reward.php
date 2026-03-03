<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class claim_challenge_reward extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'challengeid' => new external_value(PARAM_INT, 'Challenge ID'),
            'userid'      => new external_value(PARAM_INT, 'User ID (0 = current)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $challengeid, int $userid = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'challengeid' => $challengeid, 'userid' => $userid,
        ]);
        $userid = $params['userid'] ?: (int)$USER->id;

        $context = \context_system::instance();
        self::validate_context($context);

        // Get the user-challenge record.
        $uc = $DB->get_record('local_mdf_user_challenges', [
            'userid' => $userid, 'challengeid' => $params['challengeid'],
        ]);

        if (!$uc) {
            throw new \moodle_exception('challengenotfound', 'local_mdf_api');
        }

        if ($uc->status !== 'completed') {
            throw new \moodle_exception('challengenotcompleted', 'local_mdf_api');
        }

        // Get challenge for reward points.
        $challenge = $DB->get_record('local_mdf_challenges', ['id' => $params['challengeid']], '*', MUST_EXIST);

        // Mark as claimed.
        $uc->status = 'claimed';
        $uc->claimedat = time();
        $uc->timemodified = time();
        $DB->update_record('local_mdf_user_challenges', $uc);

        // Award reward points.
        \local_mdf_api\gamification_helper::award_points(
            $userid,
            (int)$challenge->rewardpoints,
            'challenge_complete',
            "Completed challenge: {$challenge->title}",
            (int)$challenge->id
        );

        // Return updated challenge.
        $sql = "SELECT c.*, uc.currentvalue, uc.status as userstatus
                FROM {local_mdf_challenges} c
                JOIN {local_mdf_user_challenges} uc ON uc.challengeid = c.id
                WHERE c.id = :cid AND uc.userid = :uid";

        $r = $DB->get_record_sql($sql, ['cid' => $challenge->id, 'uid' => $userid]);

        return get_active_challenges::format_challenge($r);
    }

    public static function execute_returns(): external_single_structure {
        return get_active_challenges::challenge_structure();
    }
}
