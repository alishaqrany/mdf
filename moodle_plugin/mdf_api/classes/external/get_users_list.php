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
 * Lightweight searchable user list for recipient picker.
 *
 * @package    local_mdf_api
 */
class get_users_list extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'search'   => new external_value(PARAM_TEXT, 'Search term (name or email)', VALUE_DEFAULT, ''),
            'courseid' => new external_value(PARAM_INT, 'Filter by course enrollment (0=all)', VALUE_DEFAULT, 0),
            'cohortid' => new external_value(PARAM_INT, 'Filter by cohort membership (0=all)', VALUE_DEFAULT, 0),
            'page'     => new external_value(PARAM_INT, 'Page number (0-based)', VALUE_DEFAULT, 0),
            'perpage'  => new external_value(PARAM_INT, 'Items per page', VALUE_DEFAULT, 20),
        ]);
    }

    public static function execute(
        string $search = '',
        int $courseid = 0,
        int $cohortid = 0,
        int $page = 0,
        int $perpage = 20
    ): array {
        global $DB, $CFG;

        $params = self::validate_parameters(self::execute_parameters(), [
            'search'   => $search,
            'courseid' => $courseid,
            'cohortid' => $cohortid,
            'page'     => $page,
            'perpage'  => $perpage,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:sendnotification', $context);

        $conditions = ["u.deleted = 0", "u.suspended = 0", "u.id > 2"];
        $sqlparams = [];
        $joins = '';

        // Search filter.
        if (!empty($params['search'])) {
            $search = '%' . $DB->sql_like_escape($params['search']) . '%';
            $conditions[] = "(" . $DB->sql_like('u.firstname', ':s1', false) .
                " OR " . $DB->sql_like('u.lastname', ':s2', false) .
                " OR " . $DB->sql_like('u.email', ':s3', false) .
                " OR " . $DB->sql_like(
                    $DB->sql_concat('u.firstname', "' '", 'u.lastname'), ':s4', false
                ) . ")";
            $sqlparams['s1'] = $search;
            $sqlparams['s2'] = $search;
            $sqlparams['s3'] = $search;
            $sqlparams['s4'] = $search;
        }

        // Course enrollment filter.
        if ($params['courseid'] > 0) {
            $joins .= " JOIN {user_enrolments} ue ON ue.userid = u.id
                         JOIN {enrol} e ON e.id = ue.enrolid AND e.courseid = :courseid";
            $sqlparams['courseid'] = $params['courseid'];
        }

        // Cohort membership filter.
        if ($params['cohortid'] > 0) {
            $joins .= " JOIN {cohort_members} cm ON cm.userid = u.id AND cm.cohortid = :cohortid";
            $sqlparams['cohortid'] = $params['cohortid'];
        }

        $where = 'WHERE ' . implode(' AND ', $conditions);

        $total = $DB->count_records_sql(
            "SELECT COUNT(DISTINCT u.id) FROM {user} u $joins $where",
            $sqlparams
        );

        $sql = "SELECT DISTINCT u.id, u.firstname, u.lastname, u.email, u.picture, u.imagealt
                  FROM {user} u
                  $joins
                  $where
              ORDER BY u.lastname, u.firstname";

        $records = $DB->get_records_sql($sql, $sqlparams,
            $params['page'] * $params['perpage'], $params['perpage']);

        $users = [];
        foreach ($records as $rec) {
            $userctx = \context_user::instance($rec->id);
            $profileimageurl = \moodle_url::make_webservice_pluginfile_url(
                $userctx->id, 'user', 'icon', null, '/', 'f1'
            )->out(false);
            $users[] = [
                'id'              => (int)$rec->id,
                'fullname'        => trim($rec->firstname . ' ' . $rec->lastname),
                'email'           => $rec->email,
                'profileimageurl' => $profileimageurl,
            ];
        }

        return [
            'total' => (int)$total,
            'users' => $users,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'total' => new external_value(PARAM_INT, 'Total matching users'),
            'users' => new external_multiple_structure(
                new external_single_structure([
                    'id'              => new external_value(PARAM_INT, 'User ID'),
                    'fullname'        => new external_value(PARAM_TEXT, 'Full name'),
                    'email'           => new external_value(PARAM_TEXT, 'Email'),
                    'profileimageurl' => new external_value(PARAM_URL, 'Profile image URL'),
                ])
            ),
        ]);
    }
}
