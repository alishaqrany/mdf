<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once($CFG->dirroot . '/cohort/lib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Delete a cohort by ID.
 */
class delete_cohort extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cohortid' => new external_value(PARAM_INT, 'Cohort ID to delete'),
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

        $cohort = $DB->get_record('cohort', ['id' => $params['cohortid']], '*', MUST_EXIST);
        cohort_delete_cohort($cohort);

        return ['success' => true];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether deletion succeeded'),
        ]);
    }
}
