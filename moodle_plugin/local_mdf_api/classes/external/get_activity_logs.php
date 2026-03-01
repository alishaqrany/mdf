<?php
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Moodle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Moodle.  If not, see <http://www.gnu.org/licenses/>.

namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_multiple_structure;
use core_external\external_value;

/**
 * Get activity logs with flexible filtering.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class get_activity_logs extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid'    => new external_value(PARAM_INT,
                'Filter by user ID (0 for all)', VALUE_DEFAULT, 0),
            'courseid'  => new external_value(PARAM_INT,
                'Filter by course ID (0 for all)', VALUE_DEFAULT, 0),
            'component' => new external_value(PARAM_TEXT,
                'Filter by component (empty for all)', VALUE_DEFAULT, ''),
            'action'    => new external_value(PARAM_TEXT,
                'Filter by action: viewed, created, updated, deleted (empty for all)',
                VALUE_DEFAULT, ''),
            'timestart' => new external_value(PARAM_INT,
                'Start time filter (0 for no limit)', VALUE_DEFAULT, 0),
            'timeend'   => new external_value(PARAM_INT,
                'End time filter (0 for no limit)', VALUE_DEFAULT, 0),
            'page'      => new external_value(PARAM_INT,
                'Page number (0-based)', VALUE_DEFAULT, 0),
            'perpage'   => new external_value(PARAM_INT,
                'Results per page', VALUE_DEFAULT, 50),
        ]);
    }

    public static function execute(
        int $userid = 0,
        int $courseid = 0,
        string $component = '',
        string $action = '',
        int $timestart = 0,
        int $timeend = 0,
        int $page = 0,
        int $perpage = 50
    ): array {
        global $DB;

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:viewlogs', $context);

        $params = self::validate_parameters(self::execute_parameters(), [
            'userid'    => $userid,
            'courseid'  => $courseid,
            'component' => $component,
            'action'    => $action,
            'timestart' => $timestart,
            'timeend'   => $timeend,
            'page'      => $page,
            'perpage'   => $perpage,
        ]);

        $perpage = min($params['perpage'], 200); // Cap at 200
        $offset  = $params['page'] * $perpage;

        // Build WHERE clause.
        $where = ['1 = 1'];
        $sql_params = [];

        if ($params['userid'] > 0) {
            $where[] = 'l.userid = :userid';
            $sql_params['userid'] = $params['userid'];
        }
        if ($params['courseid'] > 0) {
            $where[] = 'l.courseid = :courseid';
            $sql_params['courseid'] = $params['courseid'];
        }
        if (!empty($params['component'])) {
            $where[] = 'l.component = :component';
            $sql_params['component'] = $params['component'];
        }
        if (!empty($params['action'])) {
            $where[] = 'l.action = :action';
            $sql_params['action'] = $params['action'];
        }
        if ($params['timestart'] > 0) {
            $where[] = 'l.timecreated >= :timestart';
            $sql_params['timestart'] = $params['timestart'];
        }
        if ($params['timeend'] > 0) {
            $where[] = 'l.timecreated <= :timeend';
            $sql_params['timeend'] = $params['timeend'];
        }

        $where_sql = implode(' AND ', $where);

        // Count total.
        $count_sql = "SELECT COUNT(l.id) FROM {logstore_standard_log} l WHERE $where_sql";
        $total = (int)$DB->count_records_sql($count_sql, $sql_params);

        // Fetch logs with user info.
        $sql = "SELECT l.id, l.userid, l.courseid, l.component, l.action,
                       l.target, l.objecttable, l.objectid,
                       l.timecreated, l.ip,
                       u.firstname, u.lastname, u.email,
                       c.shortname as courseshortname
                FROM {logstore_standard_log} l
                LEFT JOIN {user} u ON u.id = l.userid
                LEFT JOIN {course} c ON c.id = l.courseid
                WHERE $where_sql
                ORDER BY l.timecreated DESC";

        $records = $DB->get_records_sql($sql, $sql_params, $offset, $perpage);

        $logs = [];
        foreach ($records as $rec) {
            $logs[] = [
                'id'              => (int)$rec->id,
                'userid'          => (int)$rec->userid,
                'userfullname'    => trim(($rec->firstname ?? '') . ' ' . ($rec->lastname ?? '')),
                'useremail'       => $rec->email ?? '',
                'courseid'        => (int)$rec->courseid,
                'courseshortname' => $rec->courseshortname ?? '',
                'component'       => $rec->component ?? '',
                'action'          => $rec->action ?? '',
                'target'          => $rec->target ?? '',
                'objecttable'     => $rec->objecttable ?? '',
                'objectid'        => (int)($rec->objectid ?? 0),
                'ip'              => $rec->ip ?? '',
                'timecreated'     => (int)$rec->timecreated,
            ];
        }

        return [
            'logs'      => $logs,
            'total'     => $total,
            'page'      => $params['page'],
            'perpage'   => $perpage,
            'haspages'  => $total > $perpage ? 1 : 0,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'logs' => new external_multiple_structure(
                new external_single_structure([
                    'id'              => new external_value(PARAM_INT,  'Log entry ID'),
                    'userid'          => new external_value(PARAM_INT,  'User ID'),
                    'userfullname'    => new external_value(PARAM_TEXT, 'User full name'),
                    'useremail'       => new external_value(PARAM_TEXT, 'User email'),
                    'courseid'        => new external_value(PARAM_INT,  'Course ID'),
                    'courseshortname' => new external_value(PARAM_TEXT, 'Course short name'),
                    'component'       => new external_value(PARAM_TEXT, 'Component'),
                    'action'          => new external_value(PARAM_TEXT, 'Action'),
                    'target'          => new external_value(PARAM_TEXT, 'Target'),
                    'objecttable'     => new external_value(PARAM_TEXT, 'Object table'),
                    'objectid'        => new external_value(PARAM_INT,  'Object ID'),
                    'ip'              => new external_value(PARAM_TEXT, 'IP address'),
                    'timecreated'     => new external_value(PARAM_INT,  'Timestamp'),
                ])
            ),
            'total'    => new external_value(PARAM_INT, 'Total matching records'),
            'page'     => new external_value(PARAM_INT, 'Current page'),
            'perpage'  => new external_value(PARAM_INT, 'Results per page'),
            'haspages' => new external_value(PARAM_INT, 'Has multiple pages (1/0)'),
        ]);
    }
}
