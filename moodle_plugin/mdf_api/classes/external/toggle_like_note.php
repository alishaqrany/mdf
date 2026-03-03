<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class toggle_like_note extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'noteid' => new external_value(PARAM_INT, 'Note ID'),
        ]);
    }

    public static function execute(int $noteid): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['noteid' => $noteid]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;
        $nid = $params['noteid'];

        $DB->get_record('local_mdf_study_notes', ['id' => $nid], 'id', MUST_EXIST);

        $existing = $DB->get_record('local_mdf_note_likes', [
            'noteid' => $nid, 'userid' => $userid,
        ]);

        if ($existing) {
            $DB->delete_records('local_mdf_note_likes', ['id' => $existing->id]);
            $liked = false;
        } else {
            $like = new \stdClass();
            $like->noteid      = $nid;
            $like->userid      = $userid;
            $like->timecreated = time();
            $DB->insert_record('local_mdf_note_likes', $like);
            $liked = true;
        }

        $count = $DB->count_records('local_mdf_note_likes', ['noteid' => $nid]);

        return ['liked' => $liked, 'likecount' => (int)$count];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'liked'     => new external_value(PARAM_BOOL, 'Current like state'),
            'likecount' => new external_value(PARAM_INT, 'Total like count'),
        ]);
    }
}
