<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_all_badges extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'User ID to check earned status (0 = current)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $userid = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['userid' => $userid]);
        $userid = $params['userid'] ?: (int)$USER->id;

        $context = \context_system::instance();
        self::validate_context($context);

        $badges = $DB->get_records('local_mdf_badges', null, 'category ASC, rarity DESC');
        $earnedMap = [];
        $earnedRecords = $DB->get_records('local_mdf_user_badges', ['userid' => $userid]);
        foreach ($earnedRecords as $er) {
            $earnedMap[$er->badgeid] = $er->earnedat;
        }

        // Total users for earned percentage.
        $totalUsers = max(1, $DB->count_records_select('user', 'deleted = 0 AND id > 2'));

        $result = [];
        foreach ($badges as $b) {
            $earnedCount = $DB->count_records('local_mdf_user_badges', ['badgeid' => $b->id]);
            $result[] = [
                'id'               => (int)$b->id,
                'name'             => $b->name,
                'description'      => $b->description ?? '',
                'iconname'         => $b->iconname ?? 'star',
                'category'         => $b->category ?? 'general',
                'rarity'           => $b->rarity ?? 'common',
                'requiredpoints'   => (int)($b->requiredpoints ?? 0),
                'criteria'         => $b->criteria ?? '',
                'isearned'         => isset($earnedMap[$b->id]) ? 1 : 0,
                'earnedat'         => isset($earnedMap[$b->id]) ? (int)$earnedMap[$b->id] : null,
                'earnedpercentage' => round(($earnedCount / $totalUsers) * 100, 1),
            ];
        }

        return ['badges' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'badges' => new external_multiple_structure(
                self::badge_structure()
            ),
        ]);
    }

    public static function badge_structure(): external_single_structure {
        return new external_single_structure([
            'id'               => new external_value(PARAM_INT, 'Badge ID'),
            'name'             => new external_value(PARAM_TEXT, 'Badge name'),
            'description'      => new external_value(PARAM_TEXT, 'Badge description'),
            'iconname'         => new external_value(PARAM_TEXT, 'Icon name'),
            'category'         => new external_value(PARAM_TEXT, 'Category'),
            'rarity'           => new external_value(PARAM_TEXT, 'Rarity tier'),
            'requiredpoints'   => new external_value(PARAM_INT, 'Required points'),
            'criteria'         => new external_value(PARAM_TEXT, 'Criteria text', VALUE_OPTIONAL),
            'isearned'         => new external_value(PARAM_INT, '1 if earned'),
            'earnedat'         => new external_value(PARAM_INT, 'Earned timestamp', VALUE_OPTIONAL),
            'earnedpercentage' => new external_value(PARAM_FLOAT, 'Percentage of users who earned this'),
        ]);
    }
}
