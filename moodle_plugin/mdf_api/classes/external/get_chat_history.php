<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_multiple_structure;
use core_external\external_value;

/**
 * Get chat history for a user.
 */
class get_chat_history extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid'  => new external_value(PARAM_INT, 'User ID (0 = current user)', VALUE_DEFAULT, 0),
            'limit'   => new external_value(PARAM_INT, 'Max messages to return', VALUE_DEFAULT, 50),
            'before'  => new external_value(PARAM_INT, 'Return messages before this timestamp (0=latest)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $userid = 0, int $limit = 50, int $before = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'userid' => $userid, 'limit' => $limit, 'before' => $before,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:useai', $context);

        $uid = $params['userid'] > 0 ? $params['userid'] : $USER->id;

        // Admin can view any user's history; regular users can only see their own.
        if ($uid != $USER->id) {
            require_capability('local/mdf_api:manageai', $context);
        }

        $limit = min($params['limit'], 200);
        $sqlparams = ['userid' => $uid];
        $timecond = '';
        if ($params['before'] > 0) {
            $timecond = ' AND timecreated < :before';
            $sqlparams['before'] = $params['before'];
        }

        $sql = "SELECT * FROM {local_mdf_ai_messages}
                 WHERE userid = :userid{$timecond}
              ORDER BY timecreated DESC";
        $records = $DB->get_records_sql($sql, $sqlparams, 0, $limit);

        $messages = [];
        foreach (array_reverse($records) as $rec) { // Reverse to get chronological order.
            $messages[] = [
                'id'          => (int)$rec->id,
                'userid'      => (int)$rec->userid,
                'role'        => $rec->role,
                'content'     => $rec->content,
                'provider'    => $rec->provider,
                'tokensused'  => (int)$rec->tokensused,
                'timecreated' => (int)$rec->timecreated,
            ];
        }

        return ['messages' => $messages, 'total' => count($messages)];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'messages' => new external_multiple_structure(
                new external_single_structure([
                    'id'          => new external_value(PARAM_INT, 'Message ID'),
                    'userid'      => new external_value(PARAM_INT, 'User ID'),
                    'role'        => new external_value(PARAM_ALPHA, 'Role: user|assistant|system'),
                    'content'     => new external_value(PARAM_RAW, 'Message content'),
                    'provider'    => new external_value(PARAM_TEXT, 'AI provider'),
                    'tokensused'  => new external_value(PARAM_INT, 'Tokens used'),
                    'timecreated' => new external_value(PARAM_INT, 'Created timestamp'),
                ])
            ),
            'total' => new external_value(PARAM_INT, 'Messages returned'),
        ]);
    }
}
