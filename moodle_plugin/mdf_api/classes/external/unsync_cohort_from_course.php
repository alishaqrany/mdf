<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Remove cohort enrolment method from a course.
 */
class unsync_cohort_from_course extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cohortid' => new external_value(PARAM_INT, 'Cohort ID'),
            'courseid' => new external_value(PARAM_INT, 'Course ID'),
        ]);
    }

    public static function execute(int $cohortid, int $courseid): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'cohortid' => $cohortid, 'courseid' => $courseid,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managecohorts', $context);

        $instance = $DB->get_record('enrol', [
            'enrol'      => 'cohort',
            'courseid'   => $params['courseid'],
            'customint1' => $params['cohortid'],
        ]);

        if (!$instance) {
            return ['success' => true, 'message' => 'No sync found'];
        }

        $enrolplugin = enrol_get_plugin('cohort');
        $enrolplugin->delete_instance($instance);

        return ['success' => true, 'message' => 'Sync removed'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Operation succeeded'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
