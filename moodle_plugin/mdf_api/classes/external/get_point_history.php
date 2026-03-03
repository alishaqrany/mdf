<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_point_history extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'User ID (0 = current user)', VALUE_DEFAULT, 0),
            'page'   => new external_value(PARAM_INT, 'Page number (0-based)', VALUE_DEFAULT, 0),
            'limit'  => new external_value(PARAM_INT, 'Items per page', VALUE_DEFAULT, 20),
        ]);
    }

    public static function execute(int $userid = 0, int $page = 0, int $limit = 20): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'userid' => $userid, 'page' => $page, 'limit' => $limit,
        ]);
        $userid = $params['userid'] ?: (int)$USER->id;
        $page   = max(0, $params['page']);
        $limit  = min(100, max(1, $params['limit']));

        $context = \context_system::instance();
        self::validate_context($context);

        if ($userid !== (int)$USER->id) {
            require_capability('local/mdf_api:viewgamification', $context);
        }

        $offset = $page * $limit;
        $records = $DB->get_records('local_mdf_point_transactions',
            ['userid' => $userid], 'timecreated DESC', '*', $offset, $limit);

        $result = [];
        foreach ($records as $r) {
            $result[] = [
                'id'          => (int)$r->id,
                'userid'      => (int)$r->userid,
                'points'      => (int)$r->points,
                'action'      => $r->action,
                'description' => $r->description ?? '',
                'referenceid' => $r->referenceid ? (int)$r->referenceid : null,
                'timecreated' => (int)$r->timecreated,
            ];
        }

        return ['transactions' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'transactions' => new external_multiple_structure(
                new external_single_structure([
                    'id'          => new external_value(PARAM_INT, 'Transaction ID'),
                    'userid'      => new external_value(PARAM_INT, 'User ID'),
                    'points'      => new external_value(PARAM_INT, 'Points awarded'),
                    'action'      => new external_value(PARAM_TEXT, 'Action type'),
                    'description' => new external_value(PARAM_TEXT, 'Description'),
                    'referenceid' => new external_value(PARAM_INT, 'Reference object ID', VALUE_OPTIONAL),
                    'timecreated' => new external_value(PARAM_INT, 'Created timestamp'),
                ])
            ),
        ]);
    }
}
