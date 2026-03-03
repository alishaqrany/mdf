<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class leave_session extends external_api {

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

        $participant = $DB->get_record('local_mdf_session_participants', [
            'sessionid' => $sid, 'userid' => $userid,
        ]);

        if (!$participant) {
            throw new \moodle_exception('notaparticipant', 'local_mdf_api');
        }

        $participant->isactive = 0;
        $DB->update_record('local_mdf_session_participants', $participant);

        return ['success' => true, 'message' => 'Left session'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
