<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class update_group_member_role extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'groupid' => new external_value(PARAM_INT, 'Group ID'),
            'userid'  => new external_value(PARAM_INT, 'Target user ID'),
            'role'    => new external_value(PARAM_TEXT, 'New role: admin, moderator, member'),
        ]);
    }

    public static function execute(int $groupid, int $userid, string $role): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'groupid' => $groupid, 'userid' => $userid, 'role' => $role,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);

        $currentUserId = (int)$USER->id;
        $gid = $params['groupid'];

        // Validate role.
        $validRoles = ['admin', 'moderator', 'member'];
        if (!in_array($params['role'], $validRoles)) {
            throw new \moodle_exception('invalidrole', 'local_mdf_api');
        }

        // Check current user is admin of this group.
        $myMembership = $DB->get_record('local_mdf_group_members', [
            'groupid' => $gid, 'userid' => $currentUserId,
        ]);
        if (!$myMembership || $myMembership->role !== 'admin') {
            throw new \moodle_exception('nopermission', 'local_mdf_api');
        }

        // Get target membership.
        $targetMembership = $DB->get_record('local_mdf_group_members', [
            'groupid' => $gid, 'userid' => $params['userid'],
        ]);
        if (!$targetMembership) {
            throw new \moodle_exception('notamember', 'local_mdf_api');
        }

        $targetMembership->role = $params['role'];
        $DB->update_record('local_mdf_group_members', $targetMembership);

        return ['success' => true, 'message' => 'Role updated'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
