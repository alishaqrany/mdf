<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Set device limit for a specific user.
 *
 * @package    local_mdf_api
 */
class set_user_device_limit extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'Target user ID'),
            'max_devices' => new external_value(PARAM_INT, 'Maximum devices allowed'),
        ]);
    }

    public static function execute(int $userid, int $max_devices): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'userid' => $userid,
            'max_devices' => $max_devices,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:manageprotection', $context);

        $now = time();
        $existing = $DB->get_record('local_mdf_device_limits', ['userid' => $params['userid']]);

        if ($existing) {
            $existing->maxdevices = $params['max_devices'];
            $existing->timemodified = $now;
            $DB->update_record('local_mdf_device_limits', $existing);
        } else {
            $DB->insert_record('local_mdf_device_limits', (object)[
                'userid' => $params['userid'],
                'maxdevices' => $params['max_devices'],
                'timecreated' => $now,
                'timemodified' => $now,
            ]);
        }

        // Log.
        $DB->insert_record('local_mdf_protection_log', (object)[
            'userid' => $params['userid'],
            'action' => 'settings_changed',
            'details' => "Device limit set to {$params['max_devices']} by admin {$USER->id}",
            'devicename' => '',
            'platform' => '',
            'ipaddress' => getremoteaddr(),
            'timecreated' => $now,
        ]);

        return ['success' => true];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether limit was set'),
        ]);
    }
}
