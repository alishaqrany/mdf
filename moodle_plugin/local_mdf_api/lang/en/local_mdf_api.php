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
 * Language strings for local_mdf_api (English).
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

$string['pluginname'] = 'MDF Academy API';

// Capabilities.
$string['mdf_api:viewstats'] = 'View dashboard statistics';
$string['mdf_api:viewlogs'] = 'View activity logs';
$string['mdf_api:bulkenrol'] = 'Bulk enrol users';
$string['mdf_api:sendnotification'] = 'Send push notifications';

// Settings page.
$string['settings_heading'] = 'MDF Academy API Settings';
$string['settings_heading_desc'] = 'Configure the MDF Academy mobile API plugin.';
$string['enable_push'] = 'Enable push notifications';
$string['enable_push_desc'] = 'When enabled, push notifications will be sent to mobile devices via Firebase Cloud Messaging for key events (enrolment, grades, forum posts, etc.).';
$string['fcm_server_key'] = 'FCM Server Key';
$string['fcm_server_key_desc'] = 'The Firebase Cloud Messaging server key (legacy) from your Firebase project console. Found under Project Settings → Cloud Messaging → Server key.';

// Error strings.
$string['fcmkeynotconfigured'] = 'FCM server key is not configured. Please set it in the plugin settings.';
$string['notokenfound'] = 'No FCM token registered for this user.';
$string['usernotfound'] = 'User not found.';
$string['useralreadyenrolled'] = 'User is already enrolled in this course.';
$string['enrolpluginnotavailable'] = 'Manual enrolment plugin is not available.';
$string['invalidjsondata'] = 'The data field must contain valid JSON.';

// Bulk enrol.
$string['bulkenrol_success'] = 'User successfully enrolled.';
$string['bulkenrol_failed'] = 'Failed to enrol user.';

// Push notification templates.
$string['push_enrolled_title'] = 'New Course Enrolment';
$string['push_enrolled_body'] = 'You have been enrolled in: {$a}';

$string['push_completed_title'] = 'Course Completed! 🎉';
$string['push_completed_body'] = 'Congratulations! You have completed: {$a}';

$string['push_submitted_title'] = 'New Assignment Submission';
$string['push_submitted_body'] = '{$a->student} submitted an assignment in {$a->course}';

$string['push_graded_title'] = 'New Grade Available';
$string['push_graded_body'] = 'A new grade has been posted in: {$a}';

$string['push_forum_title'] = 'New Forum Post';
$string['push_forum_body'] = '{$a->author} posted: {$a->subject}';

// Privacy API.
$string['privacy:metadata:local_mdf_fcm_tokens'] = 'Stores Firebase Cloud Messaging tokens for push notifications.';
$string['privacy:metadata:local_mdf_fcm_tokens:userid'] = 'The user ID.';
$string['privacy:metadata:local_mdf_fcm_tokens:token'] = 'The FCM device token.';
$string['privacy:metadata:local_mdf_fcm_tokens:platform'] = 'Device platform (android/ios).';
$string['privacy:metadata:local_mdf_fcm_tokens:devicename'] = 'Device name.';

$string['privacy:metadata:local_mdf_push_log'] = 'Log of push notifications sent to users.';
$string['privacy:metadata:local_mdf_push_log:userid'] = 'The recipient user ID.';
$string['privacy:metadata:local_mdf_push_log:title'] = 'Notification title.';
$string['privacy:metadata:local_mdf_push_log:body'] = 'Notification body.';
