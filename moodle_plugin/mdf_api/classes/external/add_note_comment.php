<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class add_note_comment extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'noteid'  => new external_value(PARAM_INT, 'Note ID'),
            'content' => new external_value(PARAM_RAW, 'Comment content'),
        ]);
    }

    public static function execute(int $noteid, string $content): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'noteid' => $noteid, 'content' => $content,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;
        $nid = $params['noteid'];

        $DB->get_record('local_mdf_study_notes', ['id' => $nid], 'id', MUST_EXIST);

        $comment = new \stdClass();
        $comment->noteid      = $nid;
        $comment->userid      = $userid;
        $comment->content     = $params['content'];
        $comment->timecreated = time();
        $comment->id = $DB->insert_record('local_mdf_note_comments', $comment);

        $author = $DB->get_record('user', ['id' => $userid], 'id, firstname, lastname');

        return [
            'id'                  => (int)$comment->id,
            'noteid'              => (int)$comment->noteid,
            'userid'              => $userid,
            'userfullname'        => $author ? trim($author->firstname . ' ' . $author->lastname) : '',
            'userprofileimageurl' => '',
            'content'             => $comment->content,
            'timecreated'         => (int)$comment->timecreated,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return get_note_comments::comment_structure();
    }
}
