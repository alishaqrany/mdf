<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class get_badge_detail extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'badgeid' => new external_value(PARAM_INT, 'Badge ID'),
            'userid'  => new external_value(PARAM_INT, 'User ID (0 = current)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $badgeid, int $userid = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'badgeid' => $badgeid, 'userid' => $userid,
        ]);
        $userid = $params['userid'] ?: (int)$USER->id;

        $context = \context_system::instance();
        self::validate_context($context);

        $badge = $DB->get_record('local_mdf_badges', ['id' => $params['badgeid']], '*', MUST_EXIST);

        $earned = $DB->get_record('local_mdf_user_badges', [
            'userid' => $userid, 'badgeid' => $badge->id,
        ]);

        $totalUsers = max(1, $DB->count_records_select('user', 'deleted = 0 AND id > 2'));
        $earnedCount = $DB->count_records('local_mdf_user_badges', ['badgeid' => $badge->id]);

        return [
            'id'               => (int)$badge->id,
            'name'             => $badge->name,
            'description'      => $badge->description ?? '',
            'iconname'         => $badge->iconname ?? 'star',
            'category'         => $badge->category ?? 'general',
            'rarity'           => $badge->rarity ?? 'common',
            'requiredpoints'   => (int)($badge->requiredpoints ?? 0),
            'criteria'         => $badge->criteria ?? '',
            'isearned'         => $earned ? 1 : 0,
            'earnedat'         => $earned ? (int)$earned->earnedat : null,
            'earnedpercentage' => round(($earnedCount / $totalUsers) * 100, 1),
        ];
    }

    public static function execute_returns(): external_single_structure {
        return get_all_badges::badge_structure();
    }
}
