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
 * Get AI usage statistics across all users (admin).
 */
class get_ai_usage_stats extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'days' => new external_value(PARAM_INT, 'Stats for last N days', VALUE_DEFAULT, 30),
        ]);
    }

    public static function execute(int $days = 30): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'days' => $days,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:manageai', $context);

        $since = time() - ($params['days'] * 86400);

        // Total messages.
        $totalmessages = (int)$DB->count_records_select('local_mdf_ai_messages',
            'timecreated > :since', ['since' => $since]);

        // Total tokens.
        $totaltokens = (int)$DB->get_field_sql(
            'SELECT COALESCE(SUM(tokensused), 0) FROM {local_mdf_ai_messages} WHERE timecreated > :since',
            ['since' => $since]
        );

        // Unique users.
        $uniqueusers = (int)$DB->get_field_sql(
            'SELECT COUNT(DISTINCT userid) FROM {local_mdf_ai_messages} WHERE timecreated > :since',
            ['since' => $since]
        );

        // Per-provider breakdown.
        $sql = "SELECT provider, COUNT(*) AS msgcount, COALESCE(SUM(tokensused), 0) AS tokensum
                  FROM {local_mdf_ai_messages}
                 WHERE timecreated > :since
              GROUP BY provider
              ORDER BY msgcount DESC";
        $providerrecs = $DB->get_records_sql($sql, ['since' => $since]);
        $providers = [];
        foreach ($providerrecs as $rec) {
            $providers[] = [
                'provider'   => $rec->provider,
                'messages'   => (int)$rec->msgcount,
                'tokens'     => (int)$rec->tokensum,
            ];
        }

        // Top users.
        $sql = "SELECT m.userid, u.firstname, u.lastname, u.email,
                       COUNT(*) AS msgcount, COALESCE(SUM(m.tokensused), 0) AS tokensum
                  FROM {local_mdf_ai_messages} m
                  JOIN {user} u ON u.id = m.userid
                 WHERE m.timecreated > :since AND m.role = 'user'
              GROUP BY m.userid, u.firstname, u.lastname, u.email
              ORDER BY msgcount DESC";
        $userrecs = $DB->get_records_sql($sql, ['since' => $since], 0, 20);
        $topusers = [];
        foreach ($userrecs as $rec) {
            $topusers[] = [
                'userid'    => (int)$rec->userid,
                'fullname'  => trim($rec->firstname . ' ' . $rec->lastname),
                'email'     => $rec->email,
                'messages'  => (int)$rec->msgcount,
                'tokens'    => (int)$rec->tokensum,
            ];
        }

        return [
            'totalmessages' => $totalmessages,
            'totaltokens'   => $totaltokens,
            'uniqueusers'   => $uniqueusers,
            'days'          => $params['days'],
            'providers'     => $providers,
            'topusers'      => $topusers,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'totalmessages' => new external_value(PARAM_INT, 'Total messages in period'),
            'totaltokens'   => new external_value(PARAM_INT, 'Total tokens in period'),
            'uniqueusers'   => new external_value(PARAM_INT, 'Unique users'),
            'days'          => new external_value(PARAM_INT, 'Period in days'),
            'providers' => new external_multiple_structure(
                new external_single_structure([
                    'provider' => new external_value(PARAM_TEXT, 'Provider name'),
                    'messages' => new external_value(PARAM_INT, 'Message count'),
                    'tokens'   => new external_value(PARAM_INT, 'Token count'),
                ])
            ),
            'topusers' => new external_multiple_structure(
                new external_single_structure([
                    'userid'   => new external_value(PARAM_INT, 'User ID'),
                    'fullname' => new external_value(PARAM_TEXT, 'Full name'),
                    'email'    => new external_value(PARAM_TEXT, 'Email'),
                    'messages' => new external_value(PARAM_INT, 'Message count'),
                    'tokens'   => new external_value(PARAM_INT, 'Token count'),
                ])
            ),
        ]);
    }
}
