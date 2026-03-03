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
 * Get system health information for the admin dashboard.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class get_system_health extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([]);
    }

    public static function execute(): array {
        global $DB, $CFG;

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:viewstats', $context);

        // Moodle version.
        $moodle_version  = $CFG->release ?? 'unknown';
        $moodle_build    = $CFG->version ?? 0;

        // PHP version.
        $php_version = phpversion();

        // Database info.
        $db_type = $CFG->dbtype ?? 'unknown';
        $db_size_bytes = 0;
        try {
            if (strpos($db_type, 'mysql') !== false || strpos($db_type, 'mariadb') !== false) {
                $sql = "SELECT SUM(data_length + index_length) as total_size
                        FROM information_schema.TABLES
                        WHERE table_schema = :dbname";
                $rec = $DB->get_record_sql($sql, ['dbname' => $CFG->dbname]);
                $db_size_bytes = (int)($rec->total_size ?? 0);
            } else if (strpos($db_type, 'pgsql') !== false) {
                $sql = "SELECT pg_database_size(current_database()) as total_size";
                $rec = $DB->get_record_sql($sql);
                $db_size_bytes = (int)($rec->total_size ?? 0);
            }
        } catch (\Exception $e) {
            $db_size_bytes = -1; // Indicate unavailable.
        }

        // Disk usage (moodledata).
        $dataroot_size = 0;
        if (is_dir($CFG->dataroot)) {
            // Use du if available (Linux), otherwise estimate from files table.
            if (strtoupper(substr(PHP_OS, 0, 3)) !== 'WIN') {
                $output = [];
                exec("du -sb " . escapeshellarg($CFG->dataroot) . " 2>/dev/null", $output);
                if (!empty($output[0])) {
                    $parts = preg_split('/\s+/', trim($output[0]));
                    $dataroot_size = (int)($parts[0] ?? 0);
                }
            }
            // Fallback: sum from files table.
            if ($dataroot_size === 0) {
                $dataroot_size = (int)$DB->get_field_sql(
                    "SELECT SUM(filesize) FROM {files} WHERE filesize > 0"
                );
            }
        }

        // Disk free space.
        $free_space = @disk_free_space($CFG->dataroot);
        $free_space = $free_space !== false ? (int)$free_space : -1;

        // Cron status.
        $last_cron = (int)get_config('tool_task', 'lastcronstart');
        if ($last_cron === 0) {
            // Fallback: check task_scheduled.
            $last_cron = (int)$DB->get_field_sql(
                "SELECT MAX(lastruntime) FROM {task_scheduled} WHERE lastruntime > 0"
            );
        }
        $cron_overdue = (time() - $last_cron) > 600; // >10 minutes overdue.

        // Active plugins count.
        $active_plugins = (int)$DB->count_records_select('config_plugins',
            "plugin LIKE 'mod_%' AND name = 'version'");

        // Total site files.
        $total_files = (int)$DB->count_records('files', ['component' => 'mod_resource']);
        $total_all_files = (int)$DB->count_records_select('files', 'filesize > 0');

        // Cache stores.
        $cache_stores = 0;
        try {
            $cache_stores = (int)$DB->count_records('cache_stores');
        } catch (\Exception $e) {
            // Table may not exist in some installations.
        }

        // Server uptime (Linux only).
        $server_uptime = 0;
        if (strtoupper(substr(PHP_OS, 0, 3)) !== 'WIN' && is_readable('/proc/uptime')) {
            $uptime = @file_get_contents('/proc/uptime');
            if ($uptime !== false) {
                $parts = explode(' ', trim($uptime));
                $server_uptime = (int)($parts[0] ?? 0);
            }
        }

        // Memory usage.
        $memory_usage = memory_get_usage(true);
        $memory_peak  = memory_get_peak_usage(true);
        $memory_limit = self::parse_php_size(ini_get('memory_limit'));

        // Pending tasks.
        $pending_adhoc = (int)$DB->count_records_select('task_adhoc',
            'nextruntime <= :now', ['now' => time()]);

        // Failed tasks (last 24h).
        $failed_tasks = (int)$DB->count_records_select('task_log',
            "result = 1 AND timestart > :since", ['since' => time() - 86400]);

        return [
            'moodle_version'      => $moodle_version,
            'moodle_build'        => (int)$moodle_build,
            'php_version'         => $php_version,
            'db_type'             => $db_type,
            'db_size_bytes'       => $db_size_bytes,
            'dataroot_size_bytes' => $dataroot_size,
            'free_disk_bytes'     => $free_space,
            'last_cron_time'      => $last_cron,
            'cron_overdue'        => $cron_overdue ? 1 : 0,
            'active_plugins'      => $active_plugins,
            'total_files'         => $total_all_files,
            'cache_stores'        => $cache_stores,
            'server_uptime_secs'  => $server_uptime,
            'memory_usage_bytes'  => (int)$memory_usage,
            'memory_peak_bytes'   => (int)$memory_peak,
            'memory_limit_bytes'  => (int)$memory_limit,
            'pending_adhoc_tasks' => $pending_adhoc,
            'failed_tasks_24h'    => $failed_tasks,
            'server_time'         => time(),
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'moodle_version'      => new external_value(PARAM_TEXT, 'Moodle release string'),
            'moodle_build'        => new external_value(PARAM_INT,  'Moodle build number'),
            'php_version'         => new external_value(PARAM_TEXT, 'PHP version'),
            'db_type'             => new external_value(PARAM_TEXT, 'Database type'),
            'db_size_bytes'       => new external_value(PARAM_INT,  'Database size in bytes'),
            'dataroot_size_bytes' => new external_value(PARAM_INT,  'Moodledata size in bytes'),
            'free_disk_bytes'     => new external_value(PARAM_INT,  'Free disk space in bytes'),
            'last_cron_time'      => new external_value(PARAM_INT,  'Last cron run timestamp'),
            'cron_overdue'        => new external_value(PARAM_INT,  'Cron overdue flag (1/0)'),
            'active_plugins'      => new external_value(PARAM_INT,  'Number of active activity plugins'),
            'total_files'         => new external_value(PARAM_INT,  'Total files count'),
            'cache_stores'        => new external_value(PARAM_INT,  'Number of cache stores'),
            'server_uptime_secs'  => new external_value(PARAM_INT,  'Server uptime in seconds'),
            'memory_usage_bytes'  => new external_value(PARAM_INT,  'Current memory usage'),
            'memory_peak_bytes'   => new external_value(PARAM_INT,  'Peak memory usage'),
            'memory_limit_bytes'  => new external_value(PARAM_INT,  'PHP memory limit'),
            'pending_adhoc_tasks' => new external_value(PARAM_INT,  'Pending adhoc tasks'),
            'failed_tasks_24h'    => new external_value(PARAM_INT,  'Failed tasks in last 24h'),
            'server_time'         => new external_value(PARAM_INT,  'Current server timestamp'),
        ]);
    }

    /**
     * Parse PHP size notation (128M, 1G) to bytes.
     */
    private static function parse_php_size(string $size): int {
        $size = trim($size);
        if ($size === '-1') {
            return -1; // Unlimited.
        }
        $unit = strtolower(substr($size, -1));
        $value = (int)$size;
        switch ($unit) {
            case 'g': $value *= 1024 * 1024 * 1024; break;
            case 'm': $value *= 1024 * 1024; break;
            case 'k': $value *= 1024; break;
        }
        return $value;
    }
}
