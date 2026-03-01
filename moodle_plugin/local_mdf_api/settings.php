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
 * Plugin settings page for local_mdf_api.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

if ($hassiteconfig) {
    $settings = new admin_settingpage('local_mdf_api',
        get_string('pluginname', 'local_mdf_api'));

    // Enable push notifications.
    $settings->add(new admin_setting_configcheckbox(
        'local_mdf_api/enable_push',
        get_string('enable_push', 'local_mdf_api'),
        get_string('enable_push_desc', 'local_mdf_api'),
        0
    ));

    // FCM Server Key.
    $settings->add(new admin_setting_configpasswordunmask(
        'local_mdf_api/fcm_server_key',
        get_string('fcm_server_key', 'local_mdf_api'),
        get_string('fcm_server_key_desc', 'local_mdf_api'),
        ''
    ));

    $ADMIN->add('localplugins', $settings);
}
