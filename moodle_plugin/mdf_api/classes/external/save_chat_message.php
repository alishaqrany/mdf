<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Save a chat message (user or assistant).
 */
class save_chat_message extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid'     => new external_value(PARAM_INT, 'User ID (0 for current user)', VALUE_DEFAULT, 0),
            'role'       => new external_value(PARAM_ALPHA, 'Message role: user|assistant|system'),
            'content'    => new external_value(PARAM_RAW, 'Message content'),
            'provider'   => new external_value(PARAM_ALPHANUMEXT, 'AI provider used', VALUE_DEFAULT, 'local'),
            'tokensused' => new external_value(PARAM_INT, 'Tokens consumed', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $userid, string $role, string $content,
                                   string $provider = 'local', int $tokensused = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'userid' => $userid, 'role' => $role, 'content' => $content,
            'provider' => $provider, 'tokensused' => $tokensused,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:useai', $context);

        $uid = $params['userid'] > 0 ? $params['userid'] : $USER->id;

        $record = new \stdClass();
        $record->userid     = $uid;
        $record->role       = $params['role'];
        $record->content    = $params['content'];
        $record->provider   = $params['provider'];
        $record->tokensused = $params['tokensused'];
        $record->timecreated = time();

        $record->id = $DB->insert_record('local_mdf_ai_messages', $record);

        // Update usage counters.
        self::increment_usage($uid);

        return ['success' => true, 'messageid' => (int)$record->id];
    }

    /**
     * Increment daily/monthly usage counters for a user.
     */
    private static function increment_usage(int $userid): void {
        global $DB;

        $limit = $DB->get_record('local_mdf_ai_limits', ['userid' => $userid]);
        $now = time();
        $today = strtotime('today');
        $monthstart = strtotime('first day of this month midnight');

        if (!$limit) {
            // Read defaults (userid=0).
            $defaults = $DB->get_record('local_mdf_ai_limits', ['userid' => 0]);
            $dailylimit   = $defaults ? (int)$defaults->dailylimit : 50;
            $monthlylimit = $defaults ? (int)$defaults->monthlylimit : 1000;

            $limit = new \stdClass();
            $limit->userid       = $userid;
            $limit->dailylimit   = $dailylimit;
            $limit->monthlylimit = $monthlylimit;
            $limit->dailycount   = 1;
            $limit->monthlycount = 1;
            $limit->lastreset    = $now;
            $limit->timemodified = $now;
            $DB->insert_record('local_mdf_ai_limits', $limit);
            return;
        }

        // Reset counters if needed.
        if ($limit->lastreset < $today) {
            $limit->dailycount = 0;
        }
        if ($limit->lastreset < $monthstart) {
            $limit->monthlycount = 0;
        }

        $limit->dailycount   = (int)$limit->dailycount + 1;
        $limit->monthlycount = (int)$limit->monthlycount + 1;
        $limit->lastreset    = $now;
        $limit->timemodified = $now;
        $DB->update_record('local_mdf_ai_limits', $limit);
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success'   => new external_value(PARAM_BOOL, 'Whether save succeeded'),
            'messageid' => new external_value(PARAM_INT, 'Message record ID'),
        ]);
    }
}
