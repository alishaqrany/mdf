<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class update_note extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'noteid'  => new external_value(PARAM_INT, 'Note ID'),
            'title'   => new external_value(PARAM_TEXT, 'Updated title'),
            'content' => new external_value(PARAM_RAW, 'Updated content'),
            'tags'    => new external_value(PARAM_TEXT, 'Comma-separated tags', VALUE_DEFAULT, ''),
        ]);
    }

    public static function execute(int $noteid, string $title, string $content, string $tags = ''): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'noteid' => $noteid, 'title' => $title, 'content' => $content, 'tags' => $tags,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;

        $note = $DB->get_record('local_mdf_study_notes', ['id' => $params['noteid']], '*', MUST_EXIST);

        // Only author can edit.
        if ((int)$note->userid !== $userid) {
            require_capability('local/mdf_api:managenotes', $context);
        }

        $note->title        = $params['title'];
        $note->content      = $params['content'];
        $note->tags         = $params['tags'];
        $note->timemodified = time();
        $DB->update_record('local_mdf_study_notes', $note);

        return get_course_notes::format_note($note, $userid);
    }

    public static function execute_returns(): external_single_structure {
        return get_course_notes::note_structure();
    }
}
