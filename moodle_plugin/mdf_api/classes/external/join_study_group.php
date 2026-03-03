<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class join_study_group extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'groupid' => new external_value(PARAM_INT, 'Group ID to join'),
        ]);
    }

    public static function execute(int $groupid): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['groupid' => $groupid]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;
        $gid = $params['groupid'];

        $group = $DB->get_record('local_mdf_study_groups', ['id' => $gid], '*', MUST_EXIST);

        // Check not already a member.
        if ($DB->record_exists('local_mdf_group_members', ['groupid' => $gid, 'userid' => $userid])) {
            throw new \moodle_exception('alreadymember', 'local_mdf_api');
        }

        // Check max members.
        $currentCount = $DB->count_records('local_mdf_group_members', ['groupid' => $gid]);
        if ($currentCount >= (int)$group->maxmembers) {
            throw new \moodle_exception('groupfull', 'local_mdf_api');
        }

        $member = new \stdClass();
        $member->groupid    = $gid;
        $member->userid     = $userid;
        $member->role       = 'member';
        $member->timejoined = time();
        $DB->insert_record('local_mdf_group_members', $member);

        return ['success' => true, 'message' => 'Joined successfully'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
