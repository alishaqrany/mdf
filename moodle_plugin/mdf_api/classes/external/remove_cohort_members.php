<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once($CFG->dirroot . '/cohort/lib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_multiple_structure;
use core_external\external_value;

/**
 * Remove users from a cohort.
 */
class remove_cohort_members extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cohortid' => new external_value(PARAM_INT, 'Cohort ID'),
            'userids'  => new external_multiple_structure(
                new external_value(PARAM_INT, 'User ID')
            ),
        ]);
    }

    public static function execute(int $cohortid, array $userids): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'cohortid' => $cohortid, 'userids' => $userids,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managecohorts', $context);

        if (!$DB->record_exists('cohort', ['id' => $params['cohortid']])) {
            throw new \invalid_parameter_exception('Cohort not found');
        }

        $removed = 0;
        $skipped = 0;

        foreach ($params['userids'] as $uid) {
            if (!$DB->record_exists('cohort_members', ['cohortid' => $params['cohortid'], 'userid' => $uid])) {
                $skipped++;
                continue;
            }
            cohort_remove_member($params['cohortid'], $uid);
            $removed++;
        }

        return [
            'success' => 1,
            'removed' => $removed,
            'skipped' => $skipped,
            'message' => "Removed $removed members, skipped $skipped",
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_INT, 'Success flag'),
            'removed' => new external_value(PARAM_INT, 'Number removed'),
            'skipped' => new external_value(PARAM_INT, 'Number skipped'),
            'message' => new external_value(PARAM_TEXT, 'Result message'),
        ]);
    }
}
