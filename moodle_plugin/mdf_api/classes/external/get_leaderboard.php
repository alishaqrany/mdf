<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_leaderboard extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'period'   => new external_value(PARAM_TEXT, 'Period: all, weekly, monthly', VALUE_DEFAULT, 'all'),
            'courseid' => new external_value(PARAM_INT, 'Optional course filter', VALUE_DEFAULT, 0),
            'limit'    => new external_value(PARAM_INT, 'Max entries to return', VALUE_DEFAULT, 50),
        ]);
    }

    public static function execute(string $period = 'all', int $courseid = 0, int $limit = 50): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'period' => $period, 'courseid' => $courseid, 'limit' => $limit,
        ]);
        $limit = min(200, max(1, $params['limit']));

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:viewleaderboard', $context);

        $currentUserId = (int)$USER->id;

        // Build query based on period.
        if ($params['period'] === 'weekly') {
            $since = strtotime('monday this week');
            $sql = "SELECT pt.userid, SUM(pt.points) as points
                    FROM {local_mdf_point_transactions} pt
                    WHERE pt.timecreated >= :since
                    GROUP BY pt.userid
                    ORDER BY points DESC";
            $records = $DB->get_records_sql($sql, ['since' => $since], 0, $limit);
        } else if ($params['period'] === 'monthly') {
            $since = mktime(0, 0, 0, date('m'), 1, date('Y'));
            $sql = "SELECT pt.userid, SUM(pt.points) as points
                    FROM {local_mdf_point_transactions} pt
                    WHERE pt.timecreated >= :since
                    GROUP BY pt.userid
                    ORDER BY points DESC";
            $records = $DB->get_records_sql($sql, ['since' => $since], 0, $limit);
        } else {
            // Lifetime.
            $sql = "SELECT userid, totalpoints as points, level, currentstreak
                    FROM {local_mdf_user_points}
                    ORDER BY totalpoints DESC";
            $records = $DB->get_records_sql($sql, [], 0, $limit);
        }

        $entries = [];
        $rank = 0;
        foreach ($records as $r) {
            $rank++;
            $user = $DB->get_record('user', ['id' => $r->userid],
                'id, firstname, lastname, picture, imagealt, email');
            $fullname = $user ? trim($user->firstname . ' ' . $user->lastname) : 'Unknown';

            // Get level and badge count if not from the all-time query.
            $level = $r->level ?? 1;
            $streak = $r->currentstreak ?? 0;
            if ($params['period'] !== 'all') {
                $profile = $DB->get_record('local_mdf_user_points', ['userid' => $r->userid]);
                $level = $profile ? (int)$profile->level : 1;
                $streak = $profile ? (int)$profile->currentstreak : 0;
            }

            $badgeCount = $DB->count_records('local_mdf_user_badges', ['userid' => $r->userid]);

            $entries[] = [
                'rank'            => $rank,
                'userid'          => (int)$r->userid,
                'fullname'        => $fullname,
                'profileimageurl' => '',
                'points'          => (int)$r->points,
                'level'           => (int)$level,
                'badgecount'      => (int)$badgeCount,
                'currentstreak'   => (int)$streak,
                'iscurrentuser'   => ((int)$r->userid === $currentUserId) ? 1 : 0,
            ];
        }

        return ['entries' => $entries];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'entries' => new external_multiple_structure(
                new external_single_structure([
                    'rank'            => new external_value(PARAM_INT, 'Rank position'),
                    'userid'          => new external_value(PARAM_INT, 'User ID'),
                    'fullname'        => new external_value(PARAM_TEXT, 'Full name'),
                    'profileimageurl' => new external_value(PARAM_URL, 'Profile image URL', VALUE_OPTIONAL),
                    'points'          => new external_value(PARAM_INT, 'Total points in period'),
                    'level'           => new external_value(PARAM_INT, 'Current level'),
                    'badgecount'      => new external_value(PARAM_INT, 'Number of badges earned'),
                    'currentstreak'   => new external_value(PARAM_INT, 'Current streak'),
                    'iscurrentuser'   => new external_value(PARAM_INT, '1 if current user'),
                ])
            ),
        ]);
    }
}
