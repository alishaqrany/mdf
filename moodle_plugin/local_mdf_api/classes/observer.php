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

namespace local_mdf_api;

defined('MOODLE_INTERNAL') || die();

/**
 * Event observer — sends FCM push notifications for key Moodle events.
 *
 * Push notifications are only sent if:
 *  1. The user has registered an FCM token via register_fcm_token.
 *  2. The plugin setting 'enable_push' is enabled.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class observer {

    /**
     * User has been enrolled in a course.
     *
     * @param \core\event\user_enrolment_created $event
     */
    public static function on_user_enrolled(\core\event\user_enrolment_created $event): void {
        global $DB;

        $userid   = $event->relateduserid;
        $courseid = $event->courseid;

        $course = $DB->get_record('course', ['id' => $courseid], 'id, fullname');
        if (!$course) {
            return;
        }

        self::send_to_user($userid, [
            'title' => get_string('push_enrolled_title', 'local_mdf_api'),
            'body'  => get_string('push_enrolled_body', 'local_mdf_api', $course->fullname),
            'data'  => json_encode([
                'type'      => 'enrollment',
                'courseid'  => $courseid,
            ]),
        ]);
    }

    /**
     * A course has been completed by a user.
     *
     * @param \core\event\course_completed $event
     */
    public static function on_course_completed(\core\event\course_completed $event): void {
        global $DB;

        $userid   = $event->relateduserid;
        $courseid = $event->courseid;

        $course = $DB->get_record('course', ['id' => $courseid], 'id, fullname');
        if (!$course) {
            return;
        }

        self::send_to_user($userid, [
            'title' => get_string('push_completed_title', 'local_mdf_api'),
            'body'  => get_string('push_completed_body', 'local_mdf_api', $course->fullname),
            'data'  => json_encode([
                'type'      => 'completion',
                'courseid'  => $courseid,
            ]),
        ]);
    }

    /**
     * An assignment has been submitted.
     * Notify the course teachers.
     *
     * @param \mod_assign\event\assessable_submitted $event
     */
    public static function on_assignment_submitted(\mod_assign\event\assessable_submitted $event): void {
        global $DB;

        $studentid = $event->userid;
        $courseid  = $event->courseid;

        $student = $DB->get_record('user', ['id' => $studentid], 'id, firstname, lastname');
        $course  = $DB->get_record('course', ['id' => $courseid], 'id, fullname');
        if (!$student || !$course) {
            return;
        }

        $studentname = trim($student->firstname . ' ' . $student->lastname);

        // Get teachers and editing-teachers in the course context.
        $context = \context_course::instance($courseid, IGNORE_MISSING);
        if (!$context) {
            return;
        }

        $teachers = get_enrolled_users($context, 'mod/assign:grade');
        foreach ($teachers as $teacher) {
            self::send_to_user($teacher->id, [
                'title' => get_string('push_submitted_title', 'local_mdf_api'),
                'body'  => get_string('push_submitted_body', 'local_mdf_api', (object)[
                    'student' => $studentname,
                    'course'  => $course->fullname,
                ]),
                'data' => json_encode([
                    'type'      => 'submission',
                    'courseid'  => $courseid,
                    'studentid' => $studentid,
                ]),
            ]);
        }
    }

    /**
     * A grade has been given to a user.
     *
     * @param \core\event\user_graded $event
     */
    public static function on_user_graded(\core\event\user_graded $event): void {
        global $DB;

        $userid   = $event->relateduserid;
        $courseid = $event->courseid;

        $course = $DB->get_record('course', ['id' => $courseid], 'id, fullname');
        if (!$course) {
            return;
        }

        self::send_to_user($userid, [
            'title' => get_string('push_graded_title', 'local_mdf_api'),
            'body'  => get_string('push_graded_body', 'local_mdf_api', $course->fullname),
            'data'  => json_encode([
                'type'      => 'grade',
                'courseid'  => $courseid,
            ]),
        ]);
    }

    /**
     * A new forum post has been created.
     * Notify the post author's course participants.
     *
     * @param \mod_forum\event\post_created $event
     */
    public static function on_forum_post_created(\mod_forum\event\post_created $event): void {
        global $DB;

        $authorid = $event->userid;
        $courseid = $event->courseid;

        $author = $DB->get_record('user', ['id' => $authorid], 'id, firstname, lastname');
        $course = $DB->get_record('course', ['id' => $courseid], 'id, fullname');
        if (!$author || !$course) {
            return;
        }

        $authorname = trim($author->firstname . ' ' . $author->lastname);

        // Get the discussion topic.
        $post = $DB->get_record('forum_posts', ['id' => $event->objectid], 'id, discussion, subject');
        $subject = $post->subject ?? get_string('pluginname', 'mod_forum');

        // Notify enrolled users (except the author), limited to first 100 to avoid overload.
        $context = \context_course::instance($courseid, IGNORE_MISSING);
        if (!$context) {
            return;
        }

        $enrolled = get_enrolled_users($context, '', 0, 'u.id', null, 0, 100);
        foreach ($enrolled as $user) {
            if ((int)$user->id === (int)$authorid) {
                continue;
            }
            self::send_to_user($user->id, [
                'title' => get_string('push_forum_title', 'local_mdf_api'),
                'body'  => get_string('push_forum_body', 'local_mdf_api', (object)[
                    'author'  => $authorname,
                    'subject' => $subject,
                ]),
                'data' => json_encode([
                    'type'      => 'forum',
                    'courseid'  => $courseid,
                    'postid'    => $event->objectid,
                ]),
            ]);
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /**
     * Send a push notification to a single user via all their registered FCM tokens.
     *
     * @param int   $userid
     * @param array $notification ['title', 'body', 'data']
     */
    private static function send_to_user(int $userid, array $notification): void {
        global $DB;

        // Check if push is enabled.
        if (!get_config('local_mdf_api', 'enable_push')) {
            return;
        }

        $fcm_key = get_config('local_mdf_api', 'fcm_server_key');
        if (empty($fcm_key)) {
            return;
        }

        $tokens = $DB->get_records('local_mdf_fcm_tokens', ['userid' => $userid]);
        if (empty($tokens)) {
            return;
        }

        foreach ($tokens as $token_record) {
            self::fire_fcm($fcm_key, $token_record, $userid, $notification);
        }
    }

    /**
     * Fire a single FCM request and log the result.
     */
    private static function fire_fcm(
        string $fcm_key,
        \stdClass $token_record,
        int $userid,
        array $notification
    ): void {
        global $DB, $USER;

        $payload = [
            'to' => $token_record->token,
            'notification' => [
                'title' => $notification['title'],
                'body'  => $notification['body'],
                'sound' => 'default',
            ],
            'data'     => json_decode($notification['data'] ?? '{}', true) ?? [],
            'priority' => 'high',
        ];

        $ch = curl_init('https://fcm.googleapis.com/fcm/send');
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => [
                'Authorization: key=' . $fcm_key,
                'Content-Type: application/json',
            ],
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_TIMEOUT        => 5,
            CURLOPT_CONNECTTIMEOUT => 3,
        ]);

        $response_body = curl_exec($ch);
        $http_code     = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        $response = json_decode($response_body, true);
        $success  = ($http_code === 200 && !empty($response['success']));
        $status   = $success ? 'sent' : 'failed';

        // Log.
        $log = new \stdClass();
        $log->userid      = $userid;
        $log->senderid    = $USER->id ?? 0;
        $log->title       = $notification['title'];
        $log->body        = $notification['body'];
        $log->data        = $notification['data'] ?? '{}';
        $log->status      = $status;
        $log->fcm_response = $response_body ?: '';
        $log->timecreated  = time();

        try {
            $DB->insert_record('local_mdf_push_log', $log);
        } catch (\Exception $e) {
            // Silently fail logging — don't break the event pipeline.
            debugging('local_mdf_api push log failed: ' . $e->getMessage(), DEBUG_DEVELOPER);
        }

        // Remove invalid tokens.
        if (!$success && !empty($response['results'][0]['error'])) {
            $error = $response['results'][0]['error'];
            if (in_array($error, ['NotRegistered', 'InvalidRegistration', 'MismatchSenderId'])) {
                $DB->delete_records('local_mdf_fcm_tokens', ['id' => $token_record->id]);
            }
        }
    }
}
