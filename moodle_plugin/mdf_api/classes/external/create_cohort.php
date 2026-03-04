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
 * Create a new system-level cohort.
 */
class create_cohort extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'name'        => new external_value(PARAM_TEXT, 'Cohort name'),
            'idnumber'    => new external_value(PARAM_RAW, 'ID number (optional)', VALUE_DEFAULT, ''),
            'description' => new external_value(PARAM_RAW, 'Description (optional)', VALUE_DEFAULT, ''),
            'visible'     => new external_value(PARAM_INT, 'Visible (1=yes, 0=no)', VALUE_DEFAULT, 1),
        ]);
    }

    public static function execute(string $name, string $idnumber = '', string $description = '', int $visible = 1): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'name' => $name, 'idnumber' => $idnumber,
            'description' => $description, 'visible' => $visible,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managecohorts', $context);

        $cohort = new \stdClass();
        $cohort->contextid    = $context->id;
        $cohort->name         = $params['name'];
        $cohort->idnumber     = $params['idnumber'];
        $cohort->description  = $params['description'];
        $cohort->descriptionformat = FORMAT_HTML;
        $cohort->visible      = $params['visible'];

        $cohort->id = cohort_add_cohort($cohort);

        return [
            'id'   => (int)$cohort->id,
            'name' => $cohort->name,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'id'   => new external_value(PARAM_INT, 'New cohort ID'),
            'name' => new external_value(PARAM_TEXT, 'Cohort name'),
        ]);
    }
}
