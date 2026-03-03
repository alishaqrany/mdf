<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class add_session_note extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'sessionid' => new external_value(PARAM_INT, 'Session ID'),
            'content'   => new external_value(PARAM_RAW, 'Note content'),
        ]);
    }

    public static function execute(int $sessionid, string $content): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'sessionid' => $sessionid, 'content' => $content,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;
        $sid = $params['sessionid'];

        $session = $DB->get_record('local_mdf_collab_sessions', ['id' => $sid], '*', MUST_EXIST);

        // Must be a participant.
        if (!$DB->record_exists('local_mdf_session_participants', [
            'sessionid' => $sid, 'userid' => $userid,
        ])) {
            throw new \moodle_exception('notaparticipant', 'local_mdf_api');
        }

        $note = new \stdClass();
        $note->sessionid   = $sid;
        $note->userid      = $userid;
        $note->content     = $params['content'];
        $note->timecreated = time();
        $note->id = $DB->insert_record('local_mdf_session_notes', $note);

        $author = $DB->get_record('user', ['id' => $userid], 'id, firstname, lastname');

        return [
            'id'            => (int)$note->id,
            'sessionid'     => (int)$note->sessionid,
            'userid'        => $userid,
            'userfullname'  => $author ? trim($author->firstname . ' ' . $author->lastname) : '',
            'content'       => $note->content,
            'timecreated'   => (int)$note->timecreated,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'id'           => new external_value(PARAM_INT, 'Note ID'),
            'sessionid'    => new external_value(PARAM_INT, 'Session ID'),
            'userid'       => new external_value(PARAM_INT, 'Author ID'),
            'userfullname' => new external_value(PARAM_TEXT, 'Author name'),
            'content'      => new external_value(PARAM_RAW, 'Content'),
            'timecreated'  => new external_value(PARAM_INT, 'Created timestamp'),
        ]);
    }
}
