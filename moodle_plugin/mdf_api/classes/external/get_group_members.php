<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_group_members extends external_api {

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
        require_capability('local/mdf_api:viewstudygroups', $context);

        $gid = $params['groupid'];
        $DB->get_record('local_mdf_study_groups', ['id' => $gid], 'id', MUST_EXIST);

        $members = $DB->get_records('local_mdf_group_members', ['groupid' => $gid], 'timejoined ASC');
        $fiveMinAgo = time() - 300;

        $result = [];
        foreach ($members as $m) {
            $u = $DB->get_record('user', ['id' => $m->userid], 'id, firstname, lastname, lastaccess');
            if (!$u) continue;
            $result[] = [
                'userid'          => (int)$m->userid,
                'fullname'        => trim($u->firstname . ' ' . $u->lastname),
                'profileimageurl' => '',
                'role'            => $m->role ?? 'member',
                'timejoined'      => (int)$m->timejoined,
                'isonline'        => ($u->lastaccess > $fiveMinAgo),
            ];
        }

        return ['members' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'members' => new external_multiple_structure(
                new external_single_structure([
                    'userid'          => new external_value(PARAM_INT, 'User ID'),
                    'fullname'        => new external_value(PARAM_TEXT, 'Full name'),
                    'profileimageurl' => new external_value(PARAM_URL, 'Profile image', VALUE_OPTIONAL),
                    'role'            => new external_value(PARAM_TEXT, 'Role in group'),
                    'timejoined'      => new external_value(PARAM_INT, 'Joined timestamp'),
                    'isonline'        => new external_value(PARAM_BOOL, 'Online status'),
                ])
            ),
        ]);
    }
}
