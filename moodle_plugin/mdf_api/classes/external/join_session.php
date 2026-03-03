<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class join_session extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'sessionid' => new external_value(PARAM_INT, 'Session ID'),
        ]);
    }

    public static function execute(int $sessionid): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['sessionid' => $sessionid]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;
        $sid = $params['sessionid'];

        $session = $DB->get_record('local_mdf_collab_sessions', ['id' => $sid], '*', MUST_EXIST);

        if ($session->status === 'ended' || $session->status === 'cancelled') {
            throw new \moodle_exception('sessionnotactive', 'local_mdf_api');
        }

        // Check not already joined.
        if ($DB->record_exists('local_mdf_session_participants', ['sessionid' => $sid, 'userid' => $userid])) {
            // Re-activate if inactive.
            $existing = $DB->get_record('local_mdf_session_participants', ['sessionid' => $sid, 'userid' => $userid]);
            if (!(int)$existing->isactive) {
                $existing->isactive = 1;
                $DB->update_record('local_mdf_session_participants', $existing);
            }
            return ['success' => true, 'message' => 'Already a participant'];
        }

        // Check max participants.
        $current = $DB->count_records('local_mdf_session_participants', ['sessionid' => $sid, 'isactive' => 1]);
        if ($current >= (int)$session->maxparticipants) {
            throw new \moodle_exception('sessionfull', 'local_mdf_api');
        }

        $p = new \stdClass();
        $p->sessionid  = $sid;
        $p->userid     = $userid;
        $p->isactive   = 1;
        $p->timejoined = time();
        $DB->insert_record('local_mdf_session_participants', $p);

        return ['success' => true, 'message' => 'Joined session'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
