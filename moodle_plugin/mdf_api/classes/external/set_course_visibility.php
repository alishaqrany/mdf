<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Set course visibility override.
 * Supports hiding a course for: all users, specific user(s), or a cohort.
 */
class set_course_visibility extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'courseid'   => new external_value(PARAM_INT, 'Course ID'),
            'targettype' => new external_value(PARAM_ALPHA, 'Target: all, user, or cohort'),
            'targetid'   => new external_value(PARAM_INT, 'Target ID (user/cohort ID, 0 for all)', VALUE_DEFAULT, 0),
            'hidden'     => new external_value(PARAM_INT, '1 = hidden, 0 = visible (remove override)', VALUE_DEFAULT, 1),
        ]);
    }

    public static function execute(int $courseid, string $targettype, int $targetid = 0, int $hidden = 1): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'courseid'   => $courseid,
            'targettype' => $targettype,
            'targetid'   => $targetid,
            'hidden'     => $hidden,
        ]);

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

        // Validate target type.
        $allowed = ['all', 'user', 'cohort'];
        if (!in_array($params['targettype'], $allowed)) {
            throw new \invalid_parameter_exception('targettype must be: all, user, or cohort');
        }

        // Validate course exists.
        if (!$DB->record_exists('course', ['id' => $params['courseid']])) {
            throw new \invalid_parameter_exception('Course not found');
        }

        // Validate target exists.
        if ($params['targettype'] === 'user' && $params['targetid'] > 0) {
            if (!$DB->record_exists('user', ['id' => $params['targetid'], 'deleted' => 0])) {
                throw new \invalid_parameter_exception('User not found');
            }
        }
        if ($params['targettype'] === 'cohort' && $params['targetid'] > 0) {
            if (!$DB->record_exists('cohort', ['id' => $params['targetid']])) {
                throw new \invalid_parameter_exception('Cohort not found');
            }
        }
        if ($params['targettype'] === 'all') {
            $params['targetid'] = 0;
        }

        $now = time();
        $lookup = [
            'courseid'   => $params['courseid'],
            'targettype' => $params['targettype'],
            'targetid'   => $params['targetid'],
        ];

        $existing = $DB->get_record('local_mdf_course_visibility', $lookup);

        if ($params['hidden'] == 0) {
            // Remove override (make visible again).
            if ($existing) {
                $DB->delete_records('local_mdf_course_visibility', ['id' => $existing->id]);
            }
            return ['success' => 1, 'message' => 'Visibility override removed', 'id' => 0];
        }

        if ($existing) {
            // Update existing.
            $existing->hidden = 1;
            $existing->timemodified = $now;
            $DB->update_record('local_mdf_course_visibility', $existing);
            return ['success' => 1, 'message' => 'Visibility override updated', 'id' => (int)$existing->id];
        }

        // Insert new.
        $record = (object)[
            'courseid'     => $params['courseid'],
            'targettype'   => $params['targettype'],
            'targetid'     => $params['targetid'],
            'hidden'       => 1,
            'timecreated'  => $now,
            'timemodified' => $now,
        ];
        $id = $DB->insert_record('local_mdf_course_visibility', $record);

        return ['success' => 1, 'message' => 'Course hidden successfully', 'id' => (int)$id];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_INT, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Result message'),
            'id'      => new external_value(PARAM_INT, 'Override record ID'),
        ]);
    }
}
