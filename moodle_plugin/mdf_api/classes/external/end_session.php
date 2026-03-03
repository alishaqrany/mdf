<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class end_session extends external_api {

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
        require_capability('local/mdf_api:managesessions', $context);

        $userid = (int)$USER->id;
        $sid = $params['sessionid'];

        $session = $DB->get_record('local_mdf_collab_sessions', ['id' => $sid], '*', MUST_EXIST);

        // Only the creator or a user with manage capability can end.
        if ((int)$session->createdby !== $userid) {
            require_capability('local/mdf_api:managesessions', $context);
        }

        $session->status       = 'ended';
        $session->endtime      = time();
        $session->timemodified = time();
        $DB->update_record('local_mdf_collab_sessions', $session);

        // Mark all participants inactive.
        $DB->execute("UPDATE {local_mdf_session_participants} SET isactive = 0 WHERE sessionid = ?", [$sid]);

        return ['success' => true, 'message' => 'Session ended'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
