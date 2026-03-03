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
 * Get all system-level cohorts.
 */
class get_cohorts extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'search'  => new external_value(PARAM_TEXT, 'Optional search query', VALUE_DEFAULT, ''),
            'page'    => new external_value(PARAM_INT, 'Page number (0-based)', VALUE_DEFAULT, 0),
            'perpage' => new external_value(PARAM_INT, 'Results per page (max 100)', VALUE_DEFAULT, 50),
        ]);
    }

    public static function execute(string $search = '', int $page = 0, int $perpage = 50): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'search' => $search, 'page' => $page, 'perpage' => $perpage,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managecohorts', $context);

        $perpage = min($params['perpage'], 100);
        $offset = $params['page'] * $perpage;

        $searchsql = '';
        $sqlparams = [];
        if (!empty($params['search'])) {
            $searchsql = ' WHERE ' . $DB->sql_like('name', ':search', false);
            $sqlparams['search'] = '%' . $params['search'] . '%';
        }

        $total = (int)$DB->count_records_sql('SELECT COUNT(1) FROM {cohort}' . $searchsql, $sqlparams);
        $records = $DB->get_records_sql(
            'SELECT * FROM {cohort}' . $searchsql . ' ORDER BY name ASC',
            $sqlparams,
            $offset,
            $perpage
        );

        $cohorts = [];
        foreach ($records as $rec) {
            $membercount = $DB->count_records('cohort_members', ['cohortid' => $rec->id]);
            $cohorts[] = [
                'id'          => (int)$rec->id,
                'name'        => $rec->name,
                'idnumber'    => $rec->idnumber ?? '',
                'description' => $rec->description ?? '',
                'visible'     => (int)$rec->visible,
                'membercount' => (int)$membercount,
                'timecreated' => (int)$rec->timecreated,
                'timemodified' => (int)$rec->timemodified,
            ];
        }

        return ['cohorts' => $cohorts, 'total' => (int)$total];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'cohorts' => new external_multiple_structure(
                new external_single_structure([
                    'id'          => new external_value(PARAM_INT, 'Cohort ID'),
                    'name'        => new external_value(PARAM_TEXT, 'Cohort name'),
                    'idnumber'    => new external_value(PARAM_TEXT, 'ID number'),
                    'description' => new external_value(PARAM_RAW, 'Description'),
                    'visible'     => new external_value(PARAM_INT, 'Visible flag'),
                    'membercount' => new external_value(PARAM_INT, 'Number of members'),
                    'timecreated' => new external_value(PARAM_INT, 'Created timestamp'),
                    'timemodified' => new external_value(PARAM_INT, 'Modified timestamp'),
                ])
            ),
            'total' => new external_value(PARAM_INT, 'Total cohort count'),
        ]);
    }
}
