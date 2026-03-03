<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class leave_study_group extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'groupid' => new external_value(PARAM_INT, 'Group ID to leave'),
        ]);
    }

    public static function execute(int $groupid): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['groupid' => $groupid]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;
        $gid = $params['groupid'];

        $membership = $DB->get_record('local_mdf_group_members', [
            'groupid' => $gid, 'userid' => $userid,
        ]);

        if (!$membership) {
            throw new \moodle_exception('notamember', 'local_mdf_api');
        }

        // Admins cannot leave — they must delete the group or transfer ownership first.
        if ($membership->role === 'admin') {
            $adminCount = $DB->count_records('local_mdf_group_members', [
                'groupid' => $gid, 'role' => 'admin',
            ]);
            if ($adminCount <= 1) {
                throw new \moodle_exception('lastadmincantleave', 'local_mdf_api');
            }
        }

        $DB->delete_records('local_mdf_group_members', ['id' => $membership->id]);

        return ['success' => true, 'message' => 'Left group successfully'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
