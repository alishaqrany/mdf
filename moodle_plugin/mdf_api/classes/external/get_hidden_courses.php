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
 * Check which courses are hidden for the current user.
 * Returns a list of course IDs that should be hidden from the user's view.
 * Checks: 'all' overrides, per-user overrides, and cohort overrides.
 */
class get_hidden_courses extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([]);
    }

    public static function execute(): array {
        global $DB, $USER;

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = (int)$USER->id;

        $dbman = $DB->get_manager();
        $table = new \xmldb_table('local_mdf_course_visibility');
        if (!$dbman->table_exists($table)) {
            throw new \invalid_parameter_exception(
                'Visibility table is missing. Please run Moodle upgrade for local_mdf_api.'
            );
        }

        // Get cohort IDs for the current user.
        $cohortids = $DB->get_fieldset_sql(
            "SELECT cohortid FROM {cohort_members} WHERE userid = :userid",
            ['userid' => $userid]
        );

        // Build query for all applicable overrides.
        $sql = "SELECT DISTINCT courseid
                FROM {local_mdf_course_visibility}
                WHERE hidden = 1 AND (
                    targettype = 'all'
                    OR (targettype = 'user' AND targetid = :userid)";

        $sqlparams = ['userid' => $userid];

        if (!empty($cohortids)) {
            list($insql, $inparams) = $DB->get_in_or_equal($cohortids, SQL_PARAMS_NAMED, 'coh');
            $sql .= " OR (targettype = 'cohort' AND targetid $insql)";
            $sqlparams = array_merge($sqlparams, $inparams);
        }

        $sql .= ")";

        $courseids = $DB->get_fieldset_sql($sql, $sqlparams);

        return ['courseids' => array_map('intval', $courseids)];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'courseids' => new external_multiple_structure(
                new external_value(PARAM_INT, 'Hidden course ID')
            ),
        ]);
    }
}
