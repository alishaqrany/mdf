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
 * Get courses synced with a cohort via cohort enrolment.
 */
class get_cohort_course_syncs extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cohortid' => new external_value(PARAM_INT, 'Cohort ID'),
        ]);
    }

    public static function execute(int $cohortid): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'cohortid' => $cohortid,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managecohorts', $context);

        $sql = "SELECT e.id AS enrolid, e.courseid, e.roleid, e.status, c.fullname, c.shortname
                  FROM {enrol} e
                  JOIN {course} c ON c.id = e.courseid
                 WHERE e.enrol = 'cohort' AND e.customint1 = :cohortid
              ORDER BY c.fullname ASC";

        $records = $DB->get_records_sql($sql, ['cohortid' => $params['cohortid']]);

        $syncs = [];
        foreach ($records as $rec) {
            $syncs[] = [
                'enrolid'    => (int)$rec->enrolid,
                'courseid'   => (int)$rec->courseid,
                'fullname'   => $rec->fullname,
                'shortname'  => $rec->shortname,
                'roleid'     => (int)$rec->roleid,
                'status'     => (int)$rec->status,
            ];
        }

        return ['syncs' => $syncs, 'total' => count($syncs)];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'syncs' => new external_multiple_structure(
                new external_single_structure([
                    'enrolid'    => new external_value(PARAM_INT, 'Enrol instance ID'),
                    'courseid'   => new external_value(PARAM_INT, 'Course ID'),
                    'fullname'   => new external_value(PARAM_TEXT, 'Course full name'),
                    'shortname'  => new external_value(PARAM_TEXT, 'Course short name'),
                    'roleid'     => new external_value(PARAM_INT, 'Role ID'),
                    'status'     => new external_value(PARAM_INT, 'Enrol instance status'),
                ])
            ),
            'total' => new external_value(PARAM_INT, 'Total syncs'),
        ]);
    }
}
