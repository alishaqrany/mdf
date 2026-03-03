<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_earned_badges extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'User ID (0 = current)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $userid = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['userid' => $userid]);
        $userid = $params['userid'] ?: (int)$USER->id;

        $context = \context_system::instance();
        self::validate_context($context);

        $sql = "SELECT b.*, ub.earnedat
                FROM {local_mdf_user_badges} ub
                JOIN {local_mdf_badges} b ON b.id = ub.badgeid
                WHERE ub.userid = :userid
                ORDER BY ub.earnedat DESC";

        $records = $DB->get_records_sql($sql, ['userid' => $userid]);
        $totalUsers = max(1, $DB->count_records_select('user', 'deleted = 0 AND id > 2'));

        $result = [];
        foreach ($records as $r) {
            $earnedCount = $DB->count_records('local_mdf_user_badges', ['badgeid' => $r->id]);
            $result[] = [
                'id'               => (int)$r->id,
                'name'             => $r->name,
                'description'      => $r->description ?? '',
                'iconname'         => $r->iconname ?? 'star',
                'category'         => $r->category ?? 'general',
                'rarity'           => $r->rarity ?? 'common',
                'requiredpoints'   => (int)($r->requiredpoints ?? 0),
                'criteria'         => $r->criteria ?? '',
                'isearned'         => 1,
                'earnedat'         => (int)$r->earnedat,
                'earnedpercentage' => round(($earnedCount / $totalUsers) * 100, 1),
            ];
        }

        return ['badges' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'badges' => new external_multiple_structure(
                get_all_badges::badge_structure()
            ),
        ]);
    }
}
