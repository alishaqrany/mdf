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

    // FCM Server Key (legacy - deprecated).
    $settings->add(new admin_setting_configpasswordunmask(
        'local_mdf_api/fcm_server_key',
        get_string('fcm_server_key', 'local_mdf_api'),
        get_string('fcm_server_key_desc', 'local_mdf_api'),
        ''
    ));

    // ── FCM V1 API Settings ──
    $settings->add(new admin_setting_heading(
        'local_mdf_api/fcm_v1_heading',
        get_string('fcm_v1_heading', 'local_mdf_api'),
        get_string('fcm_v1_heading_desc', 'local_mdf_api')
    ));

    // Firebase Project ID.
    $settings->add(new admin_setting_configtext(
        'local_mdf_api/fcm_project_id',
        get_string('fcm_project_id', 'local_mdf_api'),
        get_string('fcm_project_id_desc', 'local_mdf_api'),
        '', PARAM_TEXT
    ));

    // FCM Service Account JSON.
    $settings->add(new admin_setting_configtextarea(
        'local_mdf_api/fcm_service_account_json',
        get_string('fcm_service_account_json', 'local_mdf_api'),
        get_string('fcm_service_account_json_desc', 'local_mdf_api'),
        ''
    ));

    // ── Gamification Settings ──
    $settings->add(new admin_setting_heading(
        'local_mdf_api/gamification_heading',
        get_string('gamification_heading', 'local_mdf_api'),
        get_string('gamification_heading_desc', 'local_mdf_api')
    ));

    // Enable gamification.
    $settings->add(new admin_setting_configcheckbox(
        'local_mdf_api/enable_gamification',
        get_string('enable_gamification', 'local_mdf_api'),
        get_string('enable_gamification_desc', 'local_mdf_api'),
        1
    ));

    // Points per action.
    $settings->add(new admin_setting_configtext(
        'local_mdf_api/points_course_enroll',
        get_string('points_course_enroll', 'local_mdf_api'),
        get_string('points_course_enroll_desc', 'local_mdf_api'),
        10, PARAM_INT
    ));

    $settings->add(new admin_setting_configtext(
        'local_mdf_api/points_module_complete',
        get_string('points_module_complete', 'local_mdf_api'),
        get_string('points_module_complete_desc', 'local_mdf_api'),
        100, PARAM_INT
    ));

    $settings->add(new admin_setting_configtext(
        'local_mdf_api/points_assignment_submit',
        get_string('points_assignment_submit', 'local_mdf_api'),
        get_string('points_assignment_submit_desc', 'local_mdf_api'),
        20, PARAM_INT
    ));

    $settings->add(new admin_setting_configtext(
        'local_mdf_api/points_forum_post',
        get_string('points_forum_post', 'local_mdf_api'),
        get_string('points_forum_post_desc', 'local_mdf_api'),
        5, PARAM_INT
    ));

    $settings->add(new admin_setting_configtext(
        'local_mdf_api/points_daily_login',
        get_string('points_daily_login', 'local_mdf_api'),
        get_string('points_daily_login_desc', 'local_mdf_api'),
        5, PARAM_INT
    ));

    // ── Social Features Settings ──
    $settings->add(new admin_setting_heading(
        'local_mdf_api/social_heading',
        get_string('social_heading', 'local_mdf_api'),
        get_string('social_heading_desc', 'local_mdf_api')
    ));

    // Enable social features.
    $settings->add(new admin_setting_configcheckbox(
        'local_mdf_api/enable_social',
        get_string('enable_social', 'local_mdf_api'),
        get_string('enable_social_desc', 'local_mdf_api'),
        1
    ));

    // Max members per study group.
    $settings->add(new admin_setting_configtext(
        'local_mdf_api/max_group_members',
        get_string('max_group_members', 'local_mdf_api'),
        get_string('max_group_members_desc', 'local_mdf_api'),
        30, PARAM_INT
    ));

    // Max session participants.
    $settings->add(new admin_setting_configtext(
        'local_mdf_api/max_session_participants',
        get_string('max_session_participants', 'local_mdf_api'),
        get_string('max_session_participants_desc', 'local_mdf_api'),
        20, PARAM_INT
    ));

    $ADMIN->add('localplugins', $settings);
}
