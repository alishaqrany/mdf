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
 * Get protection audit log with filters and pagination.
 *
 * @package    local_mdf_api
 */
class get_protection_log extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'page' => new external_value(PARAM_INT, 'Page number (0-based)', VALUE_DEFAULT, 0),
            'perpage' => new external_value(PARAM_INT, 'Items per page', VALUE_DEFAULT, 50),
            'action' => new external_value(PARAM_TEXT, 'Filter by action type (empty=all)', VALUE_DEFAULT, ''),
            'userid' => new external_value(PARAM_INT, 'Filter by user ID (0=all)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(
        int $page = 0,
        int $perpage = 50,
        string $action = '',
        int $userid = 0
    ): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'page' => $page,
            'perpage' => $perpage,
            'action' => $action,
            'userid' => $userid,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:manageprotection', $context);

        $conditions = [];
        $sqlparams = [];

        if (!empty($params['action'])) {
            $conditions[] = 'pl.action = :action';
            $sqlparams['action'] = $params['action'];
        }
        if ($params['userid'] > 0) {
            $conditions[] = 'pl.userid = :userid';
            $sqlparams['userid'] = $params['userid'];
        }

        $where = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';

        $total = $DB->count_records_sql(
            "SELECT COUNT(*) FROM {local_mdf_protection_log} pl $where",
            $sqlparams
        );

        $sql = "SELECT pl.*, u.firstname, u.lastname
                  FROM {local_mdf_protection_log} pl
                  LEFT JOIN {user} u ON u.id = pl.userid
                  $where
              ORDER BY pl.timecreated DESC";

        $records = $DB->get_records_sql($sql, $sqlparams,
            $params['page'] * $params['perpage'], $params['perpage']);

        $logs = [];
        foreach ($records as $rec) {
            $logs[] = [
                'id' => (int)$rec->id,
                'userid' => (int)$rec->userid,
                'user_fullname' => trim(($rec->firstname ?? '') . ' ' . ($rec->lastname ?? '')),
                'action' => $rec->action,
                'details' => $rec->details ?? '',
                'device_name' => $rec->devicename ?? '',
                'platform' => $rec->platform ?? '',
                'ip_address' => $rec->ipaddress ?? '',
                'timestamp' => (int)$rec->timecreated,
            ];
        }

        return [
            'total' => (int)$total,
            'logs' => $logs,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'total' => new external_value(PARAM_INT, 'Total records'),
            'logs' => new external_multiple_structure(
                new external_single_structure([
                    'id' => new external_value(PARAM_INT, 'Log ID'),
                    'userid' => new external_value(PARAM_INT, 'User ID'),
                    'user_fullname' => new external_value(PARAM_TEXT, 'User full name'),
                    'action' => new external_value(PARAM_TEXT, 'Action type'),
                    'details' => new external_value(PARAM_TEXT, 'Event details'),
                    'device_name' => new external_value(PARAM_TEXT, 'Device name'),
                    'platform' => new external_value(PARAM_TEXT, 'Platform'),
                    'ip_address' => new external_value(PARAM_TEXT, 'IP address'),
                    'timestamp' => new external_value(PARAM_INT, 'Unix timestamp'),
                ])
            ),
        ]);
    }
}
