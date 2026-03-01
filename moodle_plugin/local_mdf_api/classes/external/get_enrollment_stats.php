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
 * Get enrollment statistics by period.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class get_enrollment_stats extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'period' => new external_value(PARAM_ALPHA,
                'Period: day, week, month, year', VALUE_DEFAULT, 'month'),
            'months' => new external_value(PARAM_INT,
                'Number of months to look back', VALUE_DEFAULT, 6),
            'courseid' => new external_value(PARAM_INT,
                'Filter by course ID (0 for all)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(string $period = 'month', int $months = 6, int $courseid = 0): array {
        global $DB;

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:viewstats', $context);

        $params = self::validate_parameters(self::execute_parameters(), [
            'period' => $period,
            'months' => $months,
            'courseid' => $courseid,
        ]);
        $period = $params['period'];
        $months = min($params['months'], 24); // Cap at 24 months.
        $courseid = $params['courseid'];

        $data = [];
        $now = time();

        // Generate enrollment counts per period.
        for ($i = $months - 1; $i >= 0; $i--) {
            $period_start = mktime(0, 0, 0, date('m') - $i, 1, date('Y'));
            $period_end   = mktime(0, 0, 0, date('m') - $i + 1, 1, date('Y'));
            $label = date('Y-m', $period_start);

            $sql_params = [
                'timestart' => $period_start,
                'timeend'   => $period_end,
            ];

            $where_course = '';
            if ($courseid > 0) {
                $where_course = ' AND e.courseid = :courseid';
                $sql_params['courseid'] = $courseid;
            }

            // New enrollments in period.
            $enroll_sql = "SELECT COUNT(ue.id)
                           FROM {user_enrolments} ue
                           JOIN {enrol} e ON e.id = ue.enrolid
                           WHERE ue.timecreated >= :timestart
                             AND ue.timecreated < :timeend
                             $where_course";
            $new_enrollments = (int)$DB->count_records_sql($enroll_sql, $sql_params);

            // Completions in period.
            $comp_params = [
                'timestart' => $period_start,
                'timeend'   => $period_end,
            ];
            $comp_where = '';
            if ($courseid > 0) {
                $comp_where = ' AND course = :courseid';
                $comp_params['courseid'] = $courseid;
            }
            $completions = $DB->count_records_select('course_completions',
                "timecompleted >= :timestart AND timecompleted < :timeend $comp_where",
                $comp_params);

            // New users in period.
            $new_users = $DB->count_records_select('user',
                'deleted = 0 AND id > 2 AND timecreated >= :timestart AND timecreated < :timeend',
                ['timestart' => $period_start, 'timeend' => $period_end]);

            $data[] = [
                'label'           => $label,
                'new_enrollments' => $new_enrollments,
                'completions'     => (int)$completions,
                'new_users'       => (int)$new_users,
            ];
        }

        // Summary totals.
        $total_start = mktime(0, 0, 0, date('m') - $months + 1, 1, date('Y'));
        $total_enrollments = 0;
        $total_completions = 0;
        $total_new_users = 0;
        foreach ($data as $d) {
            $total_enrollments += $d['new_enrollments'];
            $total_completions += $d['completions'];
            $total_new_users   += $d['new_users'];
        }

        return [
            'periods' => $data,
            'summary' => [
                'total_enrollments' => $total_enrollments,
                'total_completions' => $total_completions,
                'total_new_users'   => $total_new_users,
                'period_type'       => $period,
                'months_covered'    => $months,
            ],
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'periods' => new external_multiple_structure(
                new external_single_structure([
                    'label'           => new external_value(PARAM_TEXT, 'Period label (YYYY-MM)'),
                    'new_enrollments' => new external_value(PARAM_INT,  'New enrollments'),
                    'completions'     => new external_value(PARAM_INT,  'Course completions'),
                    'new_users'       => new external_value(PARAM_INT,  'New user registrations'),
                ])
            ),
            'summary' => new external_single_structure([
                'total_enrollments' => new external_value(PARAM_INT,  'Total enrollments in period'),
                'total_completions' => new external_value(PARAM_INT,  'Total completions in period'),
                'total_new_users'   => new external_value(PARAM_INT,  'Total new users in period'),
                'period_type'       => new external_value(PARAM_ALPHA,'Period type'),
                'months_covered'    => new external_value(PARAM_INT,  'Months covered'),
            ]),
        ]);
    }
}
