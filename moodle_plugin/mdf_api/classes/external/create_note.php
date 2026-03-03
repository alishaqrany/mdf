<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class create_note extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'title'      => new external_value(PARAM_TEXT, 'Note title'),
            'content'    => new external_value(PARAM_RAW, 'Note content (HTML/Markdown)'),
            'courseid'   => new external_value(PARAM_INT, 'Course ID'),
            'groupid'    => new external_value(PARAM_INT, 'Group ID (0 = no group)', VALUE_DEFAULT, 0),
            'visibility' => new external_value(PARAM_TEXT, 'personal|group|course|public', VALUE_DEFAULT, 'course'),
            'tags'       => new external_value(PARAM_TEXT, 'Comma-separated tags', VALUE_DEFAULT, ''),
        ]);
    }

    public static function execute(string $title, string $content, int $courseid,
                                    int $groupid = 0, string $visibility = 'course',
                                    string $tags = ''): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'title' => $title, 'content' => $content, 'courseid' => $courseid,
            'groupid' => $groupid, 'visibility' => $visibility, 'tags' => $tags,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managenotes', $context);

        $userid = (int)$USER->id;
        $now = time();

        // Validate visibility.
        $validVis = ['personal', 'group', 'course', 'public'];
        if (!in_array($params['visibility'], $validVis)) {
            $params['visibility'] = 'course';
        }

        $note = new \stdClass();
        $note->title        = $params['title'];
        $note->content      = $params['content'];
        $note->userid       = $userid;
        $note->courseid     = $params['courseid'];
        $note->groupid      = $params['groupid'] ?: null;
        $note->modulename   = '';
        $note->visibility   = $params['visibility'];
        $note->tags         = $params['tags'];
        $note->timecreated  = $now;
        $note->timemodified = $now;
        $note->id = $DB->insert_record('local_mdf_study_notes', $note);

        // Award gamification points.
        \local_mdf_api\gamification_helper::award_points(
            $userid, 10, 'note_create',
            "Created study note: {$note->title}", (int)$note->id
        );

        return get_course_notes::format_note($note, $userid);
    }

    public static function execute_returns(): external_single_structure {
        return get_course_notes::note_structure();
    }
}
