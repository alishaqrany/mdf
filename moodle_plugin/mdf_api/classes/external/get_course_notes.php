<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_course_notes extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'courseid' => new external_value(PARAM_INT, 'Course ID'),
        ]);
    }

    public static function execute(int $courseid): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['courseid' => $courseid]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;
        $cid = $params['courseid'];

        // Get notes visible to this user in this course.
        $sql = "SELECT n.*
                FROM {local_mdf_study_notes} n
                WHERE n.courseid = :courseid
                  AND (n.visibility = 'public' OR n.visibility = 'course'
                       OR (n.visibility = 'personal' AND n.userid = :userid))
                ORDER BY n.timecreated DESC";

        $records = $DB->get_records_sql($sql, ['courseid' => $cid, 'userid' => $userid]);

        $result = [];
        foreach ($records as $n) {
            $result[] = self::format_note($n, $userid);
        }

        return ['notes' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'notes' => new external_multiple_structure(self::note_structure()),
        ]);
    }

    public static function note_structure(): external_single_structure {
        return new external_single_structure([
            'id'                  => new external_value(PARAM_INT, 'Note ID'),
            'title'               => new external_value(PARAM_TEXT, 'Title'),
            'content'             => new external_value(PARAM_RAW, 'Content'),
            'userid'              => new external_value(PARAM_INT, 'Author ID'),
            'userfullname'        => new external_value(PARAM_TEXT, 'Author name'),
            'userprofileimageurl' => new external_value(PARAM_URL, 'Author image', VALUE_OPTIONAL),
            'courseid'            => new external_value(PARAM_INT, 'Course ID'),
            'coursename'          => new external_value(PARAM_TEXT, 'Course name', VALUE_OPTIONAL),
            'modulename'          => new external_value(PARAM_TEXT, 'Module name', VALUE_OPTIONAL),
            'likes'               => new external_value(PARAM_INT, 'Like count'),
            'isliked'             => new external_value(PARAM_BOOL, 'Liked by current user'),
            'isbookmarked'        => new external_value(PARAM_BOOL, 'Bookmarked by current user'),
            'commentcount'        => new external_value(PARAM_INT, 'Comment count'),
            'visibility'          => new external_value(PARAM_TEXT, 'Visibility scope'),
            'tags'                => new external_multiple_structure(
                new external_value(PARAM_TEXT, 'Tag'), 'Tags', VALUE_OPTIONAL
            ),
            'timecreated'         => new external_value(PARAM_INT, 'Created timestamp'),
            'timemodified'        => new external_value(PARAM_INT, 'Modified timestamp'),
        ]);
    }

    public static function format_note(\stdClass $n, int $currentUserId): array {
        global $DB;

        $author = $DB->get_record('user', ['id' => $n->userid], 'id, firstname, lastname');
        $course = $DB->get_record('course', ['id' => $n->courseid], 'id, fullname');

        $likes = $DB->count_records('local_mdf_note_likes', ['noteid' => $n->id]);
        $isLiked = $DB->record_exists('local_mdf_note_likes', [
            'noteid' => $n->id, 'userid' => $currentUserId,
        ]);
        $isBookmarked = $DB->record_exists('local_mdf_note_bookmarks', [
            'noteid' => $n->id, 'userid' => $currentUserId,
        ]);
        $commentCount = $DB->count_records('local_mdf_note_comments', ['noteid' => $n->id]);

        $tags = [];
        if (!empty($n->tags)) {
            $tags = array_map('trim', explode(',', $n->tags));
        }

        return [
            'id'                  => (int)$n->id,
            'title'               => $n->title ?? '',
            'content'             => $n->content ?? '',
            'userid'              => (int)$n->userid,
            'userfullname'        => $author ? trim($author->firstname . ' ' . $author->lastname) : '',
            'userprofileimageurl' => '',
            'courseid'            => (int)$n->courseid,
            'coursename'          => $course ? $course->fullname : '',
            'modulename'          => $n->modulename ?? '',
            'likes'               => $likes,
            'isliked'             => $isLiked,
            'isbookmarked'        => $isBookmarked,
            'commentcount'        => $commentCount,
            'visibility'          => $n->visibility ?? 'course',
            'tags'                => $tags,
            'timecreated'         => (int)$n->timecreated,
            'timemodified'        => (int)$n->timemodified,
        ];
    }
}
