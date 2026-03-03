<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_group_sessions extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'groupid' => new external_value(PARAM_INT, 'Group ID'),
        ]);
    }

    public static function execute(int $groupid): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), ['groupid' => $groupid]);

        $context = \context_system::instance();
        self::validate_context($context);

        $gid = $params['groupid'];
        $group = $DB->get_record('local_mdf_study_groups', ['id' => $gid], '*', MUST_EXIST);

        $sessions = $DB->get_records('local_mdf_collab_sessions', ['groupid' => $gid], 'starttime DESC');

        $result = [];
        foreach ($sessions as $s) {
            $result[] = self::format_session($s, $group->name);
        }

        return ['sessions' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'sessions' => new external_multiple_structure(self::session_structure()),
        ]);
    }

    public static function session_structure(): external_single_structure {
        return new external_single_structure([
            'id'               => new external_value(PARAM_INT, 'Session ID'),
            'title'            => new external_value(PARAM_TEXT, 'Title'),
            'description'      => new external_value(PARAM_RAW, 'Description', VALUE_OPTIONAL),
            'groupid'          => new external_value(PARAM_INT, 'Group ID'),
            'groupname'        => new external_value(PARAM_TEXT, 'Group name'),
            'createdby'        => new external_value(PARAM_INT, 'Creator user ID'),
            'creatorname'      => new external_value(PARAM_TEXT, 'Creator name', VALUE_OPTIONAL),
            'starttime'        => new external_value(PARAM_INT, 'Start timestamp'),
            'endtime'          => new external_value(PARAM_INT, 'End timestamp', VALUE_OPTIONAL),
            'participantcount' => new external_value(PARAM_INT, 'Participant count'),
            'maxparticipants'  => new external_value(PARAM_INT, 'Max participants'),
            'status'           => new external_value(PARAM_TEXT, 'scheduled|active|ended|cancelled'),
            'topic'            => new external_value(PARAM_TEXT, 'Session topic', VALUE_OPTIONAL),
        ]);
    }

    public static function format_session(\stdClass $s, string $groupName = ''): array {
        global $DB;

        $creator = $DB->get_record('user', ['id' => $s->createdby], 'id, firstname, lastname');
        $participantCount = $DB->count_records('local_mdf_session_participants', ['sessionid' => $s->id]);

        return [
            'id'               => (int)$s->id,
            'title'            => $s->title ?? '',
            'description'      => $s->description ?? '',
            'groupid'          => (int)$s->groupid,
            'groupname'        => $groupName,
            'createdby'        => (int)$s->createdby,
            'creatorname'      => $creator ? trim($creator->firstname . ' ' . $creator->lastname) : '',
            'starttime'        => (int)$s->starttime,
            'endtime'          => $s->endtime ? (int)$s->endtime : null,
            'participantcount' => $participantCount,
            'maxparticipants'  => (int)($s->maxparticipants ?? 20),
            'status'           => $s->status ?? 'scheduled',
            'topic'            => $s->topic ?? '',
        ];
    }
}
