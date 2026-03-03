<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_study_group_detail extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'groupid' => new external_value(PARAM_INT, 'Group ID'),
        ]);
    }

    public static function execute(int $groupid): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['groupid' => $groupid]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:viewstudygroups', $context);

        $g = $DB->get_record('local_mdf_study_groups', ['id' => $params['groupid']], '*', MUST_EXIST);
        $userid = (int)$USER->id;

        $creator = $DB->get_record('user', ['id' => $g->createdby], 'id, firstname, lastname');
        $course = $DB->get_record('course', ['id' => $g->courseid], 'id, fullname');
        $memberCount = $DB->count_records('local_mdf_group_members', ['groupid' => $g->id]);
        $myRole = $DB->get_field('local_mdf_group_members', 'role',
            ['groupid' => $g->id, 'userid' => $userid]);

        // Get members.
        $memberRecords = $DB->get_records('local_mdf_group_members', ['groupid' => $g->id], 'timejoined ASC');
        $members = [];
        $fiveMinAgo = time() - 300;
        foreach ($memberRecords as $m) {
            $u = $DB->get_record('user', ['id' => $m->userid], 'id, firstname, lastname, lastaccess');
            if (!$u) continue;
            $members[] = [
                'userid'          => (int)$m->userid,
                'fullname'        => trim($u->firstname . ' ' . $u->lastname),
                'profileimageurl' => '',
                'role'            => $m->role ?? 'member',
                'timejoined'      => (int)$m->timejoined,
                'isonline'        => ($u->lastaccess > $fiveMinAgo),
            ];
        }

        return [
            'id'          => (int)$g->id,
            'name'        => $g->name,
            'description' => $g->description ?? '',
            'courseid'    => (int)$g->courseid,
            'coursename'  => $course ? $course->fullname : '',
            'createdby'   => (int)$g->createdby,
            'creatorname' => $creator ? trim($creator->firstname . ' ' . $creator->lastname) : '',
            'imageurl'    => $g->imageurl ?? '',
            'ispublic'    => (int)($g->ispublic ?? 1),
            'membercount' => $memberCount,
            'maxmembers'  => (int)($g->maxmembers ?? 30),
            'timecreated' => (int)$g->timecreated,
            'userrole'    => $myRole ?: '',
            'members'     => $members,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'id'          => new external_value(PARAM_INT, 'Group ID'),
            'name'        => new external_value(PARAM_TEXT, 'Name'),
            'description' => new external_value(PARAM_RAW, 'Description', VALUE_OPTIONAL),
            'courseid'    => new external_value(PARAM_INT, 'Course ID'),
            'coursename'  => new external_value(PARAM_TEXT, 'Course name', VALUE_OPTIONAL),
            'createdby'   => new external_value(PARAM_INT, 'Creator ID'),
            'creatorname' => new external_value(PARAM_TEXT, 'Creator name', VALUE_OPTIONAL),
            'imageurl'    => new external_value(PARAM_URL, 'Image URL', VALUE_OPTIONAL),
            'ispublic'    => new external_value(PARAM_INT, '1 if public'),
            'membercount' => new external_value(PARAM_INT, 'Member count'),
            'maxmembers'  => new external_value(PARAM_INT, 'Max members'),
            'timecreated' => new external_value(PARAM_INT, 'Created timestamp'),
            'userrole'    => new external_value(PARAM_TEXT, 'Current user role', VALUE_OPTIONAL),
            'members'     => new external_multiple_structure(
                new external_single_structure([
                    'userid'          => new external_value(PARAM_INT, 'User ID'),
                    'fullname'        => new external_value(PARAM_TEXT, 'Full name'),
                    'profileimageurl' => new external_value(PARAM_URL, 'Profile image', VALUE_OPTIONAL),
                    'role'            => new external_value(PARAM_TEXT, 'Role'),
                    'timejoined'      => new external_value(PARAM_INT, 'Joined timestamp'),
                    'isonline'        => new external_value(PARAM_BOOL, 'Currently online'),
                ])
            ),
        ]);
    }
}
