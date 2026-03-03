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
 * Get members of a specific cohort.
 */
class get_cohort_members extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cohortid' => new external_value(PARAM_INT, 'Cohort ID'),
        ]);
    }

    public static function execute(int $cohortid): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), ['cohortid' => $cohortid]);
        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managecohorts', $context);

        if (!$DB->record_exists('cohort', ['id' => $params['cohortid']])) {
            throw new \invalid_parameter_exception('Cohort not found');
        }

        $sql = "SELECT cm.id AS memberid, cm.userid, cm.timeadded,
                       u.firstname, u.lastname, u.email, u.picture, u.imagealt
                FROM {cohort_members} cm
                JOIN {user} u ON u.id = cm.userid AND u.deleted = 0
                WHERE cm.cohortid = :cohortid
                ORDER BY u.lastname, u.firstname";

        $records = $DB->get_records_sql($sql, ['cohortid' => $params['cohortid']]);

        $members = [];
        foreach ($records as $rec) {
            $members[] = [
                'userid'          => (int)$rec->userid,
                'fullname'        => trim($rec->firstname . ' ' . $rec->lastname),
                'email'           => $rec->email,
                'profileimageurl' => '',
                'timeadded'       => (int)$rec->timeadded,
            ];
        }

        return ['members' => $members, 'total' => count($members)];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'members' => new external_multiple_structure(
                new external_single_structure([
                    'userid'          => new external_value(PARAM_INT, 'User ID'),
                    'fullname'        => new external_value(PARAM_TEXT, 'Full name'),
                    'email'           => new external_value(PARAM_TEXT, 'Email'),
                    'profileimageurl' => new external_value(PARAM_TEXT, 'Profile image URL'),
                    'timeadded'       => new external_value(PARAM_INT, 'Time added to cohort'),
                ])
            ),
            'total' => new external_value(PARAM_INT, 'Total member count'),
        ]);
    }
}
