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
    // ─── Existing: Admin & Push ───
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

    // ─── Gamification: Points ───
    'local_mdf_api_get_user_points' => [
        'classname'     => 'local_mdf_api\external\get_user_points',
        'description'   => 'Get user points, level, streak profile',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewgamification',
    ],
    'local_mdf_api_get_point_history' => [
        'classname'     => 'local_mdf_api\external\get_point_history',
        'description'   => 'Get paginated point transaction history',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewgamification',
    ],
    'local_mdf_api_award_points' => [
        'classname'     => 'local_mdf_api\external\award_points',
        'description'   => 'Manually award points to a user',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:awardpoints',
    ],
    'local_mdf_api_record_daily_login' => [
        'classname'     => 'local_mdf_api\external\record_daily_login',
        'description'   => 'Record daily login and update streak',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => '',
    ],

    // ─── Gamification: Badges ───
    'local_mdf_api_get_all_badges' => [
        'classname'     => 'local_mdf_api\external\get_all_badges',
        'description'   => 'Get all badges with earned status for a user',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewgamification',
    ],
    'local_mdf_api_get_earned_badges' => [
        'classname'     => 'local_mdf_api\external\get_earned_badges',
        'description'   => 'Get only earned badges for a user',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewgamification',
    ],
    'local_mdf_api_get_badge_detail' => [
        'classname'     => 'local_mdf_api\external\get_badge_detail',
        'description'   => 'Get detailed info for a single badge',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewgamification',
    ],

    // ─── Gamification: Leaderboard ───
    'local_mdf_api_get_leaderboard' => [
        'classname'     => 'local_mdf_api\external\get_leaderboard',
        'description'   => 'Get leaderboard by period',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewleaderboard',
    ],

    // ─── Gamification: Challenges ───
    'local_mdf_api_get_active_challenges' => [
        'classname'     => 'local_mdf_api\external\get_active_challenges',
        'description'   => 'Get active challenges for a user',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewgamification',
    ],
    'local_mdf_api_get_completed_challenges' => [
        'classname'     => 'local_mdf_api\external\get_completed_challenges',
        'description'   => 'Get completed challenges for a user',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewgamification',
    ],
    'local_mdf_api_claim_challenge_reward' => [
        'classname'     => 'local_mdf_api\external\claim_challenge_reward',
        'description'   => 'Claim reward points for completed challenge',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewgamification',
    ],

    // ─── Social: Study Groups ───
    'local_mdf_api_get_study_groups' => [
        'classname'     => 'local_mdf_api\external\get_study_groups',
        'description'   => 'Get study groups, optionally filtered by course',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_get_study_group_detail' => [
        'classname'     => 'local_mdf_api\external\get_study_group_detail',
        'description'   => 'Get detailed info for a study group',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_create_study_group' => [
        'classname'     => 'local_mdf_api\external\create_study_group',
        'description'   => 'Create a new study group',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managestudygroups',
    ],
    'local_mdf_api_join_study_group' => [
        'classname'     => 'local_mdf_api\external\join_study_group',
        'description'   => 'Join an existing study group',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_leave_study_group' => [
        'classname'     => 'local_mdf_api\external\leave_study_group',
        'description'   => 'Leave a study group',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_get_group_members' => [
        'classname'     => 'local_mdf_api\external\get_group_members',
        'description'   => 'Get members of a study group',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_update_group_member_role' => [
        'classname'     => 'local_mdf_api\external\update_group_member_role',
        'description'   => 'Update a member role within a study group',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managestudygroups',
    ],
    'local_mdf_api_delete_study_group' => [
        'classname'     => 'local_mdf_api\external\delete_study_group',
        'description'   => 'Delete a study group',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managestudygroups',
    ],

    // ─── Social: Study Notes ───
    'local_mdf_api_get_course_notes' => [
        'classname'     => 'local_mdf_api\external\get_course_notes',
        'description'   => 'Get study notes for a course',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_get_group_notes' => [
        'classname'     => 'local_mdf_api\external\get_group_notes',
        'description'   => 'Get study notes for a group',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_create_note' => [
        'classname'     => 'local_mdf_api\external\create_note',
        'description'   => 'Create a study note',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managenotes',
    ],
    'local_mdf_api_update_note' => [
        'classname'     => 'local_mdf_api\external\update_note',
        'description'   => 'Update an existing study note',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managenotes',
    ],
    'local_mdf_api_delete_note' => [
        'classname'     => 'local_mdf_api\external\delete_note',
        'description'   => 'Delete a study note',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managenotes',
    ],
    'local_mdf_api_toggle_like_note' => [
        'classname'     => 'local_mdf_api\external\toggle_like_note',
        'description'   => 'Toggle like on a study note',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_toggle_bookmark_note' => [
        'classname'     => 'local_mdf_api\external\toggle_bookmark_note',
        'description'   => 'Toggle bookmark on a study note',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_get_note_comments' => [
        'classname'     => 'local_mdf_api\external\get_note_comments',
        'description'   => 'Get comments for a study note',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_add_note_comment' => [
        'classname'     => 'local_mdf_api\external\add_note_comment',
        'description'   => 'Add a comment to a study note',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managenotes',
    ],

    // ─── Social: Peer Review ───
    'local_mdf_api_get_pending_reviews' => [
        'classname'     => 'local_mdf_api\external\get_pending_reviews',
        'description'   => 'Get pending peer reviews for a user',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewpeerreviews',
    ],
    'local_mdf_api_get_completed_reviews' => [
        'classname'     => 'local_mdf_api\external\get_completed_reviews',
        'description'   => 'Get completed peer reviews',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewpeerreviews',
    ],
    'local_mdf_api_get_review_detail' => [
        'classname'     => 'local_mdf_api\external\get_review_detail',
        'description'   => 'Get detailed peer review with submission',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewpeerreviews',
    ],
    'local_mdf_api_submit_review' => [
        'classname'     => 'local_mdf_api\external\submit_review',
        'description'   => 'Submit a peer review with rating and feedback',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:submitreview',
    ],

    // ─── Social: Collaborative Sessions ───
    'local_mdf_api_get_group_sessions' => [
        'classname'     => 'local_mdf_api\external\get_group_sessions',
        'description'   => 'Get collaborative sessions for a study group',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:viewstudygroups',
    ],
    'local_mdf_api_create_session' => [
        'classname'     => 'local_mdf_api\external\create_session',
        'description'   => 'Create a collaborative session',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managesessions',
    ],
    'local_mdf_api_join_session' => [
        'classname'     => 'local_mdf_api\external\join_session',
        'description'   => 'Join a collaborative session',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managesessions',
    ],
    'local_mdf_api_leave_session' => [
        'classname'     => 'local_mdf_api\external\leave_session',
        'description'   => 'Leave a collaborative session',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managesessions',
    ],
    'local_mdf_api_end_session' => [
        'classname'     => 'local_mdf_api\external\end_session',
        'description'   => 'End a collaborative session',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managesessions',
    ],
    'local_mdf_api_add_session_note' => [
        'classname'     => 'local_mdf_api\external\add_session_note',
        'description'   => 'Add a shared note to a collaborative session',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managesessions',
    ],

    // ─── Course Visibility Management ───
    'local_mdf_api_get_course_visibility' => [
        'classname'     => 'local_mdf_api\external\get_course_visibility',
        'description'   => 'Get all course visibility overrides (admin)',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managecoursevisibility',
    ],
    'local_mdf_api_set_course_visibility' => [
        'classname'     => 'local_mdf_api\external\set_course_visibility',
        'description'   => 'Create or update a course visibility override',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managecoursevisibility',
    ],
    'local_mdf_api_remove_course_visibility' => [
        'classname'     => 'local_mdf_api\external\remove_course_visibility',
        'description'   => 'Remove a course visibility override by ID',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managecoursevisibility',
    ],
    'local_mdf_api_get_hidden_courses' => [
        'classname'     => 'local_mdf_api\external\get_hidden_courses',
        'description'   => 'Get course IDs hidden for the current user',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => '',
    ],

    // ─── Cohort Management ───
    'local_mdf_api_get_cohorts' => [
        'classname'     => 'local_mdf_api\external\get_cohorts',
        'description'   => 'Get paginated list of system cohorts with member counts',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managecohorts',
    ],
    'local_mdf_api_get_cohort_members' => [
        'classname'     => 'local_mdf_api\external\get_cohort_members',
        'description'   => 'Get members of a specific cohort',
        'type'          => 'read',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managecohorts',
    ],
    'local_mdf_api_add_cohort_members' => [
        'classname'     => 'local_mdf_api\external\add_cohort_members',
        'description'   => 'Bulk add users to a cohort',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managecohorts',
    ],
    'local_mdf_api_remove_cohort_members' => [
        'classname'     => 'local_mdf_api\external\remove_cohort_members',
        'description'   => 'Bulk remove users from a cohort',
        'type'          => 'write',
        'ajax'          => true,
        'capabilities'  => 'local/mdf_api:managecohorts',
    ],
];

$services = [
    'MDF Academy Mobile Service' => [
        'functions'         => array_values(array_unique(array_merge(
            array_keys($functions),
            [
                // Core/site functions used by the app.
                'core_webservice_get_site_info',
                'tool_mobile_get_config',
                'tool_mobile_get_public_config',

                // User management.
                'core_user_get_users',
                'core_user_get_users_by_field',
                'core_user_create_users',
                'core_user_update_users',
                'core_user_delete_users',
                'core_user_get_course_user_profiles',
                'core_user_update_picture',

                // Course/admin helpers used in admin pages and visibility UI.
                'core_course_get_courses',
                'core_course_get_courses_by_field',
                'core_course_get_categories',
                'enrol_get_users_courses',
            ]
        ))),
        'restrictedusers'   => 0,
        'enabled'           => 1,
        'shortname'         => 'mdf_mobile',
        'downloadfiles'     => 1,
        'uploadfiles'       => 1,
    ],
];
