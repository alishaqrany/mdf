<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_study_groups extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'courseid' => new external_value(PARAM_INT, 'Filter by course (0 = all)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $courseid = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['courseid' => $courseid]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:viewstudygroups', $context);

        $userid = (int)$USER->id;
        $where = '';
        $sqlparams = [];

        if ($params['courseid'] > 0) {
            $where = 'WHERE g.courseid = :courseid';
            $sqlparams['courseid'] = $params['courseid'];
        }

        $sql = "SELECT g.*,
                    (SELECT COUNT(*) FROM {local_mdf_group_members} gm WHERE gm.groupid = g.id) AS membercount,
                    (SELECT gm2.role FROM {local_mdf_group_members} gm2 WHERE gm2.groupid = g.id AND gm2.userid = :uid LIMIT 1) AS userrole
                FROM {local_mdf_study_groups} g
                $where
                ORDER BY g.timecreated DESC";

        $sqlparams['uid'] = $userid;
        $records = $DB->get_records_sql($sql, $sqlparams);

        $result = [];
        foreach ($records as $g) {
            $creator = $DB->get_record('user', ['id' => $g->createdby], 'id, firstname, lastname');
            $course = $DB->get_record('course', ['id' => $g->courseid], 'id, fullname');

            $result[] = [
                'id'          => (int)$g->id,
                'name'        => $g->name,
                'description' => $g->description ?? '',
                'courseid'    => (int)$g->courseid,
                'coursename'  => $course ? $course->fullname : '',
                'createdby'   => (int)$g->createdby,
                'creatorname' => $creator ? trim($creator->firstname . ' ' . $creator->lastname) : '',
                'imageurl'    => $g->imageurl ?? '',
                'ispublic'    => (int)($g->ispublic ?? 1),
                'membercount' => (int)($g->membercount ?? 0),
                'maxmembers'  => (int)($g->maxmembers ?? 30),
                'timecreated' => (int)$g->timecreated,
                'userrole'    => $g->userrole ?? '',
            ];
        }

        return ['groups' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'groups' => new external_multiple_structure(
                self::group_structure()
            ),
        ]);
    }

    public static function group_structure(): external_single_structure {
        return new external_single_structure([
            'id'          => new external_value(PARAM_INT, 'Group ID'),
            'name'        => new external_value(PARAM_TEXT, 'Group name'),
            'description' => new external_value(PARAM_RAW, 'Description', VALUE_OPTIONAL),
            'courseid'    => new external_value(PARAM_INT, 'Course ID'),
            'coursename'  => new external_value(PARAM_TEXT, 'Course name', VALUE_OPTIONAL),
            'createdby'   => new external_value(PARAM_INT, 'Creator user ID'),
            'creatorname' => new external_value(PARAM_TEXT, 'Creator name', VALUE_OPTIONAL),
            'imageurl'    => new external_value(PARAM_URL, 'Group image URL', VALUE_OPTIONAL),
            'ispublic'    => new external_value(PARAM_INT, '1 if public'),
            'membercount' => new external_value(PARAM_INT, 'Member count'),
            'maxmembers'  => new external_value(PARAM_INT, 'Max members'),
            'timecreated' => new external_value(PARAM_INT, 'Created timestamp'),
            'userrole'    => new external_value(PARAM_TEXT, 'Current user role', VALUE_OPTIONAL),
        ]);
    }
}
