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
 * Get push notification log (history of sent push notifications).
 *
 * @package    local_mdf_api
 */
class get_notification_log extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'page'    => new external_value(PARAM_INT, 'Page number (0-based)', VALUE_DEFAULT, 0),
            'perpage' => new external_value(PARAM_INT, 'Items per page', VALUE_DEFAULT, 20),
            'status'  => new external_value(PARAM_TEXT, 'Filter by status (sent/failed/all)', VALUE_DEFAULT, 'all'),
            'userid'  => new external_value(PARAM_INT, 'Filter by recipient user ID (0=all)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(
        int $page = 0,
        int $perpage = 20,
        string $status = 'all',
        int $userid = 0
    ): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'page'    => $page,
            'perpage' => $perpage,
            'status'  => $status,
            'userid'  => $userid,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:sendnotification', $context);

        $conditions = [];
        $sqlparams = [];

        if ($params['status'] !== 'all') {
            $conditions[] = 'pl.status = :status';
            $sqlparams['status'] = $params['status'];
        }
        if ($params['userid'] > 0) {
            $conditions[] = 'pl.userid = :userid';
            $sqlparams['userid'] = $params['userid'];
        }

        $where = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';

        $total = $DB->count_records_sql(
            "SELECT COUNT(*) FROM {local_mdf_push_log} pl $where",
            $sqlparams
        );

        $sql = "SELECT pl.*, u.firstname, u.lastname, u.email,
                       s.firstname AS senderfirstname, s.lastname AS senderlastname
                  FROM {local_mdf_push_log} pl
                  LEFT JOIN {user} u ON u.id = pl.userid
                  LEFT JOIN {user} s ON s.id = pl.senderid
                  $where
              ORDER BY pl.timecreated DESC";

        $records = $DB->get_records_sql($sql, $sqlparams,
            $params['page'] * $params['perpage'], $params['perpage']);

        $logs = [];
        foreach ($records as $rec) {
            $logs[] = [
                'id'         => (int)$rec->id,
                'userid'     => (int)$rec->userid,
                'fullname'   => trim(($rec->firstname ?? '') . ' ' . ($rec->lastname ?? '')),
                'email'      => $rec->email ?? '',
                'senderid'   => (int)$rec->senderid,
                'sendername' => trim(($rec->senderfirstname ?? '') . ' ' . ($rec->senderlastname ?? '')),
                'title'      => $rec->title,
                'body'       => $rec->body,
                'status'     => $rec->status,
                'timecreated'=> (int)$rec->timecreated,
            ];
        }

        return [
            'total' => (int)$total,
            'logs'  => $logs,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'total' => new external_value(PARAM_INT, 'Total records'),
            'logs'  => new external_multiple_structure(
                new external_single_structure([
                    'id'          => new external_value(PARAM_INT, 'Log ID'),
                    'userid'      => new external_value(PARAM_INT, 'Recipient user ID'),
                    'fullname'    => new external_value(PARAM_TEXT, 'Recipient full name'),
                    'email'       => new external_value(PARAM_TEXT, 'Recipient email'),
                    'senderid'    => new external_value(PARAM_INT, 'Sender user ID'),
                    'sendername'  => new external_value(PARAM_TEXT, 'Sender name'),
                    'title'       => new external_value(PARAM_TEXT, 'Notification title'),
                    'body'        => new external_value(PARAM_RAW, 'Notification body'),
                    'status'      => new external_value(PARAM_TEXT, 'Status'),
                    'timecreated' => new external_value(PARAM_INT, 'Unix timestamp'),
                ])
            ),
        ]);
    }
}
