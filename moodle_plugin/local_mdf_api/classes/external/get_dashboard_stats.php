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
use core_external\external_value;

/**
 * Get aggregated dashboard statistics.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class get_dashboard_stats extends external_api {

    /**
     * Parameters definition.
     */
    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([]);
    }

    /**
     * Execute — gather all dashboard statistics in a single call.
     */
    public static function execute(): array {
        global $DB;

        // Validate context and capabilities.
        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:viewstats', $context);

        // Total users (excluding deleted and guest).
        $total_users = $DB->count_records_select('user',
            'deleted = 0 AND id > 2');

        // Active users (logged in within last 30 days).
        $thirty_days_ago = time() - (30 * DAYSECS);
        $active_users = $DB->count_records_select('user',
            'deleted = 0 AND id > 2 AND lastaccess > :time',
            ['time' => $thirty_days_ago]);

        // Online users (last 5 minutes).
        $five_min_ago = time() - (5 * MINSECS);
        $online_users = $DB->count_records_select('user',
            'deleted = 0 AND lastaccess > :time',
            ['time' => $five_min_ago]);

        // Total courses (visible).
        $total_courses = $DB->count_records_select('course',
            'id > 1 AND visible = 1');

        // Total enrollments.
        $total_enrollments = $DB->count_records_select('user_enrolments',
            'status = 0');

        // New users this month.
        $month_start = mktime(0, 0, 0, date('m'), 1, date('Y'));
        $new_users_month = $DB->count_records_select('user',
            'deleted = 0 AND id > 2 AND timecreated > :time',
            ['time' => $month_start]);

        // New users this week.
        $week_start = strtotime('monday this week');
        $new_users_week = $DB->count_records_select('user',
            'deleted = 0 AND id > 2 AND timecreated > :time',
            ['time' => $week_start]);

        // Course completions this month.
        $completions_month = $DB->count_records_select('course_completions',
            'timecompleted > :time',
            ['time' => $month_start]);

        // Average course progress (across all enrolled users).
        $avg_progress_sql = "SELECT AVG(gg.finalgrade / gi.grademax * 100) as avg_progress
                             FROM {grade_grades} gg
                             JOIN {grade_items} gi ON gi.id = gg.itemid
                             WHERE gi.itemtype = 'course'
                               AND gg.finalgrade IS NOT NULL
                               AND gi.grademax > 0";
        $avg_progress_rec = $DB->get_record_sql($avg_progress_sql);
        $avg_progress = $avg_progress_rec ? round((float)$avg_progress_rec->avg_progress, 1) : 0.0;

        // Total categories.
        $total_categories = $DB->count_records('course_categories');

        // Disk usage (Moodle data files).
        $disk_usage = 0;
        $disk_sql = "SELECT SUM(filesize) as total FROM {files} WHERE filesize > 0";
        $disk_rec = $DB->get_record_sql($disk_sql);
        if ($disk_rec && $disk_rec->total) {
            $disk_usage = (int)$disk_rec->total;
        }

        return [
            'total_users'         => (int)$total_users,
            'active_users'        => (int)$active_users,
            'online_users'        => (int)$online_users,
            'total_courses'       => (int)$total_courses,
            'total_enrollments'   => (int)$total_enrollments,
            'new_users_month'     => (int)$new_users_month,
            'new_users_week'      => (int)$new_users_week,
            'completions_month'   => (int)$completions_month,
            'avg_progress'        => $avg_progress,
            'total_categories'    => (int)$total_categories,
            'disk_usage_bytes'    => $disk_usage,
        ];
    }

    /**
     * Return value definition.
     */
    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'total_users'       => new external_value(PARAM_INT,    'Total registered users'),
            'active_users'      => new external_value(PARAM_INT,    'Users active in last 30 days'),
            'online_users'      => new external_value(PARAM_INT,    'Users online in last 5 minutes'),
            'total_courses'     => new external_value(PARAM_INT,    'Total visible courses'),
            'total_enrollments' => new external_value(PARAM_INT,    'Total active enrollments'),
            'new_users_month'   => new external_value(PARAM_INT,    'New users this month'),
            'new_users_week'    => new external_value(PARAM_INT,    'New users this week'),
            'completions_month' => new external_value(PARAM_INT,    'Course completions this month'),
            'avg_progress'      => new external_value(PARAM_FLOAT,  'Average course progress %'),
            'total_categories'  => new external_value(PARAM_INT,    'Total course categories'),
            'disk_usage_bytes'  => new external_value(PARAM_INT,    'Total file storage in bytes'),
        ]);
    }
}
