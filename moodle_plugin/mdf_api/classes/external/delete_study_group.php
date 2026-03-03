<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class delete_study_group extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'groupid' => new external_value(PARAM_INT, 'Group ID to delete'),
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

        // Must be group admin or have the manage capability.
        $isAdmin = $DB->record_exists('local_mdf_group_members', [
            'groupid' => $gid, 'userid' => $userid, 'role' => 'admin',
        ]);

        if (!$isAdmin) {
            require_capability('local/mdf_api:managestudygroups', $context);
        }

        // Delete all related data.
        // Session participants and notes for sessions in this group.
        $sessionIds = $DB->get_fieldset_select('local_mdf_collab_sessions', 'id', 'groupid = ?', [$gid]);
        if (!empty($sessionIds)) {
            list($inSql, $inParams) = $DB->get_in_or_equal($sessionIds);
            $DB->delete_records_select('local_mdf_session_participants', "sessionid $inSql", $inParams);
            $DB->delete_records_select('local_mdf_session_notes', "sessionid $inSql", $inParams);
        }
        $DB->delete_records('local_mdf_collab_sessions', ['groupid' => $gid]);
        $DB->delete_records('local_mdf_group_members', ['groupid' => $gid]);
        $DB->delete_records('local_mdf_study_groups', ['id' => $gid]);

        return ['success' => true, 'message' => 'Group deleted'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
