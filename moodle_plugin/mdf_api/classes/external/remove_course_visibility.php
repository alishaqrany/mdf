<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Remove a specific course visibility override by ID.
 */
class remove_course_visibility extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'id' => new external_value(PARAM_INT, 'Override record ID'),
        ]);
    }

    public static function execute(int $id): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), ['id' => $id]);
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

        if (!$DB->record_exists('local_mdf_course_visibility', ['id' => $params['id']])) {
            throw new \invalid_parameter_exception('Override not found');
        }

        $DB->delete_records('local_mdf_course_visibility', ['id' => $params['id']]);

        return ['success' => 1, 'message' => 'Override removed'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_INT, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Result message'),
        ]);
    }
}
