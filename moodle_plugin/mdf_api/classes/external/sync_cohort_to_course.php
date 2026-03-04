<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Enable cohort-based enrolment method for a course.
 */
class sync_cohort_to_course extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cohortid' => new external_value(PARAM_INT, 'Cohort ID'),
            'courseid' => new external_value(PARAM_INT, 'Course ID'),
            'roleid'   => new external_value(PARAM_INT, 'Role ID (default 5 = student)', VALUE_DEFAULT, 5),
        ]);
    }

    public static function execute(int $cohortid, int $courseid, int $roleid = 5): array {
        global $DB, $CFG;

        $params = self::validate_parameters(self::execute_parameters(), [
            'cohortid' => $cohortid, 'courseid' => $courseid, 'roleid' => $roleid,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managecohorts', $context);

        // Verify cohort and course exist.
        $DB->get_record('cohort', ['id' => $params['cohortid']], '*', MUST_EXIST);
        $DB->get_record('course', ['id' => $params['courseid']], '*', MUST_EXIST);

        // Check if cohort enrol plugin is enabled.
        $enrolplugin = enrol_get_plugin('cohort');
        if (!$enrolplugin) {
            throw new \moodle_exception('enrolpluginnotinstalled', 'enrol', '', 'cohort');
        }

        // Check if this sync already exists.
        $existing = $DB->get_record('enrol', [
            'enrol'    => 'cohort',
            'courseid' => $params['courseid'],
            'customint1' => $params['cohortid'],
        ]);

        if ($existing) {
            // Already synced. Update status to active if disabled.
            if ($existing->status != ENROL_INSTANCE_ENABLED) {
                $enrolplugin->update_status($existing, ENROL_INSTANCE_ENABLED);
            }
            return ['success' => true, 'enrolid' => (int)$existing->id, 'created' => false];
        }

        // Add new cohort enrol instance.
        $course = $DB->get_record('course', ['id' => $params['courseid']], '*', MUST_EXIST);
        $fields = [
            'customint1' => $params['cohortid'],
            'roleid'     => $params['roleid'],
        ];
        $enrolid = $enrolplugin->add_instance($course, $fields);

        // Sync existing cohort members into the course.
        require_once($CFG->dirroot . '/enrol/cohort/locallib.php');
        $trace = new \null_progress_trace();
        enrol_cohort_sync($trace, $params['courseid']);

        return ['success' => true, 'enrolid' => (int)$enrolid, 'created' => true];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Operation succeeded'),
            'enrolid' => new external_value(PARAM_INT, 'Enrol instance ID'),
            'created' => new external_value(PARAM_BOOL, 'Whether a new instance was created'),
        ]);
    }
}
