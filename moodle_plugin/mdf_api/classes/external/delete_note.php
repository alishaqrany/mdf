<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class delete_note extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'noteid' => new external_value(PARAM_INT, 'Note ID to delete'),
        ]);
    }

    public static function execute(int $noteid): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['noteid' => $noteid]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;
        $nid = $params['noteid'];

        $note = $DB->get_record('local_mdf_study_notes', ['id' => $nid], '*', MUST_EXIST);

        if ((int)$note->userid !== $userid) {
            require_capability('local/mdf_api:managenotes', $context);
        }

        // Delete related data.
        $DB->delete_records('local_mdf_note_likes', ['noteid' => $nid]);
        $DB->delete_records('local_mdf_note_bookmarks', ['noteid' => $nid]);
        $DB->delete_records('local_mdf_note_comments', ['noteid' => $nid]);
        $DB->delete_records('local_mdf_study_notes', ['id' => $nid]);

        return ['success' => true, 'message' => 'Note deleted'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
