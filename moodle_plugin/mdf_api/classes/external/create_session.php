<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class create_session extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'title'       => new external_value(PARAM_TEXT, 'Session title'),
            'groupid'     => new external_value(PARAM_INT, 'Group ID'),
            'starttime'   => new external_value(PARAM_INT, 'Start timestamp'),
            'endtime'     => new external_value(PARAM_INT, 'End timestamp (0 = none)', VALUE_DEFAULT, 0),
            'description' => new external_value(PARAM_RAW, 'Description', VALUE_DEFAULT, ''),
            'topic'       => new external_value(PARAM_TEXT, 'Session topic', VALUE_DEFAULT, ''),
        ]);
    }

    public static function execute(string $title, int $groupid, int $starttime,
                                    int $endtime = 0, string $description = '',
                                    string $topic = ''): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'title' => $title, 'groupid' => $groupid, 'starttime' => $starttime,
            'endtime' => $endtime, 'description' => $description, 'topic' => $topic,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managesessions', $context);

        $userid = (int)$USER->id;
        $gid = $params['groupid'];

        // Verify group exists and user is a member.
        $group = $DB->get_record('local_mdf_study_groups', ['id' => $gid], '*', MUST_EXIST);
        if (!$DB->record_exists('local_mdf_group_members', ['groupid' => $gid, 'userid' => $userid])) {
            throw new \moodle_exception('notamember', 'local_mdf_api');
        }

        $now = time();
        $session = new \stdClass();
        $session->title           = $params['title'];
        $session->description     = $params['description'];
        $session->groupid         = $gid;
        $session->createdby       = $userid;
        $session->starttime       = $params['starttime'];
        $session->endtime         = $params['endtime'] ?: null;
        $session->maxparticipants = 20;
        $session->status          = ($params['starttime'] <= $now) ? 'active' : 'scheduled';
        $session->topic           = $params['topic'];
        $session->timecreated     = $now;
        $session->timemodified    = $now;
        $session->id = $DB->insert_record('local_mdf_collab_sessions', $session);

        // Auto-join the creator.
        $participant = new \stdClass();
        $participant->sessionid  = $session->id;
        $participant->userid     = $userid;
        $participant->isactive   = 1;
        $participant->timejoined = $now;
        $DB->insert_record('local_mdf_session_participants', $participant);

        return get_group_sessions::format_session($session, $group->name);
    }

    public static function execute_returns(): external_single_structure {
        return get_group_sessions::session_structure();
    }
}
