<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_multiple_structure;
use core_external\external_value;

/**
 * Get visibility overrides for courses.
 */
class get_course_visibility extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'courseid' => new external_value(PARAM_INT, 'Course ID (0 = all courses)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $courseid = 0): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), ['courseid' => $courseid]);
        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managecoursevisibility', $context);

        $dbman = $DB->get_manager();
        $table = new \xmldb_table('local_mdf_course_visibility');
        if (!$dbman->table_exists($table)) {
            throw new \invalid_parameter_exception(
                'Visibility table is missing. Please run Moodle upgrade for local_mdf_api.'
            );
        }

        $conditions = [];
        $sqlparams = [];

        if ($params['courseid'] > 0) {
            $conditions[] = 'cv.courseid = :courseid';
            $sqlparams['courseid'] = $params['courseid'];
        }

        $where = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';

        $sql = "SELECT cv.*, c.fullname AS coursename,
                       CASE cv.targettype
                           WHEN 'user' THEN u.firstname || ' ' || u.lastname
                           WHEN 'cohort' THEN co.name
                           ELSE 'all'
                       END AS targetname
                FROM {local_mdf_course_visibility} cv
                JOIN {course} c ON c.id = cv.courseid
                LEFT JOIN {user} u ON cv.targettype = 'user' AND u.id = cv.targetid
                LEFT JOIN {cohort} co ON cv.targettype = 'cohort' AND co.id = cv.targetid
                $where
                ORDER BY cv.courseid, cv.targettype, cv.timecreated DESC";

        $records = $DB->get_records_sql($sql, $sqlparams);

        $results = [];
        foreach ($records as $rec) {
            $targetname = '';
            if ($rec->targettype === 'user') {
                $user = $DB->get_record('user', ['id' => $rec->targetid], 'firstname, lastname');
                $targetname = $user ? trim($user->firstname . ' ' . $user->lastname) : 'Unknown';
            } else if ($rec->targettype === 'cohort') {
                $cohort = $DB->get_record('cohort', ['id' => $rec->targetid], 'name');
                $targetname = $cohort ? $cohort->name : 'Unknown';
            } else {
                $targetname = 'All Users';
            }

            $results[] = [
                'id'          => (int)$rec->id,
                'courseid'    => (int)$rec->courseid,
                'coursename'  => $rec->coursename,
                'targettype'  => $rec->targettype,
                'targetid'    => (int)$rec->targetid,
                'targetname'  => $targetname,
                'hidden'      => (int)$rec->hidden,
                'timecreated' => (int)$rec->timecreated,
            ];
        }

        return ['overrides' => $results];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'overrides' => new external_multiple_structure(
                new external_single_structure([
                    'id'          => new external_value(PARAM_INT, 'Override ID'),
                    'courseid'    => new external_value(PARAM_INT, 'Course ID'),
                    'coursename'  => new external_value(PARAM_TEXT, 'Course full name'),
                    'targettype'  => new external_value(PARAM_ALPHA, 'Target type: all, user, cohort'),
                    'targetid'    => new external_value(PARAM_INT, 'Target ID (0 for all)'),
                    'targetname'  => new external_value(PARAM_TEXT, 'Target display name'),
                    'hidden'      => new external_value(PARAM_INT, '1=hidden, 0=visible'),
                    'timecreated' => new external_value(PARAM_INT, 'Timestamp'),
                ])
            ),
        ]);
    }
}
