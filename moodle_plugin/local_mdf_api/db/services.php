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

/**
 * External functions and service definitions for local_mdf_api.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

$functions = [
    'local_mdf_api_get_dashboard_stats' => [
        'classname'     => 'local_mdf_api\external\get_dashboard_stats',
        'description'   => 'Get aggregated dashboard statistics for admin panel',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstats',
    ],
    'local_mdf_api_get_enrollment_stats' => [
        'classname'     => 'local_mdf_api\external\get_enrollment_stats',
        'description'   => 'Get enrollment statistics by period',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstats',
    ],
    'local_mdf_api_bulk_enrol_users' => [
        'classname'     => 'local_mdf_api\external\bulk_enrol_users',
        'description'   => 'Enroll multiple users in a course at once',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:bulkenrol',
    ],
    'local_mdf_api_get_activity_logs' => [
        'classname'     => 'local_mdf_api\external\get_activity_logs',
        'description'   => 'Get recent activity logs with filters',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewlogs',
    ],
    'local_mdf_api_get_system_health' => [
        'classname'     => 'local_mdf_api\external\get_system_health',
        'description'   => 'Get system health and performance metrics',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstats',
    ],
    'local_mdf_api_send_push_notification' => [
        'classname'     => 'local_mdf_api\external\send_push_notification',
        'description'   => 'Send push notification to users via FCM',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:sendnotification',
    ],
    'local_mdf_api_register_fcm_token' => [
        'classname'     => 'local_mdf_api\external\register_fcm_token',
        'description'   => 'Register or update FCM token for current user',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => '',
    ],
];

$services = [
    'MDF Academy Mobile Service' => [
        'functions'         => array_keys($functions),
        'restrictedusers'   => 0,
        'enabled'           => 1,
        'shortname'         => 'mdf_mobile',
        'downloadfiles'     => 1,
        'uploadfiles'       => 1,
    ],
];
