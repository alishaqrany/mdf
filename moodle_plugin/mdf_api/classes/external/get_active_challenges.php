<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_active_challenges extends external_api {

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

        $now = time();

        // Get all active challenges (not expired) with user progress.
        $sql = "SELECT c.*, COALESCE(uc.currentvalue, 0) as currentvalue,
                       COALESCE(uc.status, 'active') as userstatus
                FROM {local_mdf_challenges} c
                LEFT JOIN {local_mdf_user_challenges} uc
                    ON uc.challengeid = c.id AND uc.userid = :userid
                WHERE c.startdate <= :now1 AND c.enddate >= :now2
                ORDER BY c.enddate ASC";

        $records = $DB->get_records_sql($sql, [
            'userid' => $userid, 'now1' => $now, 'now2' => $now,
        ]);

        $result = [];
        foreach ($records as $r) {
            if ($r->userstatus === 'claimed') {
                continue; // Already claimed.
            }
            $result[] = self::format_challenge($r);
        }

        return ['challenges' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'challenges' => new external_multiple_structure(
                self::challenge_structure()
            ),
        ]);
    }

    public static function challenge_structure(): external_single_structure {
        return new external_single_structure([
            'id'           => new external_value(PARAM_INT, 'Challenge ID'),
            'title'        => new external_value(PARAM_TEXT, 'Title'),
            'description'  => new external_value(PARAM_TEXT, 'Description'),
            'type'         => new external_value(PARAM_TEXT, 'Challenge type'),
            'period'       => new external_value(PARAM_TEXT, 'daily or weekly'),
            'targetvalue'  => new external_value(PARAM_INT, 'Target value'),
            'currentvalue' => new external_value(PARAM_INT, 'Current progress'),
            'rewardpoints' => new external_value(PARAM_INT, 'Reward points'),
            'startdate'    => new external_value(PARAM_INT, 'Start timestamp'),
            'enddate'      => new external_value(PARAM_INT, 'End timestamp'),
            'status'       => new external_value(PARAM_TEXT, 'active/completed/expired/claimed'),
        ]);
    }

    public static function format_challenge(\stdClass $r): array {
        $status = $r->userstatus ?? 'active';
        if ($status === 'active' && (int)$r->currentvalue >= (int)$r->targetvalue) {
            $status = 'completed';
        }
        if ($status === 'active' && time() > (int)$r->enddate) {
            $status = 'expired';
        }

        return [
            'id'           => (int)$r->id,
            'title'        => $r->title,
            'description'  => $r->description ?? '',
            'type'         => $r->type ?? 'module_complete',
            'period'       => $r->period ?? 'daily',
            'targetvalue'  => (int)$r->targetvalue,
            'currentvalue' => (int)$r->currentvalue,
            'rewardpoints' => (int)$r->rewardpoints,
            'startdate'    => (int)$r->startdate,
            'enddate'      => (int)$r->enddate,
            'status'       => $status,
        ];
    }
}
