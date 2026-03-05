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
 * Get devices registered for a user.
 *
 * @package    local_mdf_api
 */
class get_user_devices extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'User ID (0 = current user)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $userid = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'userid' => $userid,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);

        $targetUserId = $params['userid'] > 0 ? $params['userid'] : $USER->id;

        // Non-admins can only view their own devices.
        if ($targetUserId !== $USER->id) {
            require_capability('local/mdf_api:manageprotection', $context);
        }

        $records = $DB->get_records('local_mdf_user_devices', ['userid' => $targetUserId], 'lastactive DESC');

        // Get device limit for user.
        $maxDevices = self::get_user_device_limit($targetUserId);

        $devices = [];
        foreach ($records as $rec) {
            $devices[] = [
                'id' => (int)$rec->id,
                'userid' => (int)$rec->userid,
                'device_id' => $rec->deviceid,
                'device_name' => $rec->devicename,
                'platform' => $rec->platform,
                'os_version' => $rec->osversion ?? '',
                'app_version' => $rec->appversion ?? '',
                'last_active' => (int)$rec->lastactive,
                'registered_at' => (int)$rec->timecreated,
            ];
        }

        return [
            'devices' => $devices,
            'max_devices' => $maxDevices,
            'total' => count($devices),
        ];
    }

    private static function get_user_device_limit(int $userid): int {
        global $DB;

        if (is_siteadmin($userid)) {
            return 999; // Unlimited for admins.
        }

        $userLimit = $DB->get_record('local_mdf_device_limits', ['userid' => $userid]);
        if ($userLimit) {
            return (int)$userLimit->maxdevices;
        }

        $settings = $DB->get_record('local_mdf_protection_settings', ['id' => 1]);
        return $settings ? (int)$settings->defaultmaxdevices : 3;
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'devices' => new external_multiple_structure(
                new external_single_structure([
                    'id' => new external_value(PARAM_INT, 'Device record ID'),
                    'userid' => new external_value(PARAM_INT, 'User ID'),
                    'device_id' => new external_value(PARAM_TEXT, 'Unique device identifier'),
                    'device_name' => new external_value(PARAM_TEXT, 'Device name'),
                    'platform' => new external_value(PARAM_TEXT, 'Platform'),
                    'os_version' => new external_value(PARAM_TEXT, 'OS version'),
                    'app_version' => new external_value(PARAM_TEXT, 'App version'),
                    'last_active' => new external_value(PARAM_INT, 'Last active timestamp'),
                    'registered_at' => new external_value(PARAM_INT, 'Registration timestamp'),
                ])
            ),
            'max_devices' => new external_value(PARAM_INT, 'Maximum devices allowed'),
            'total' => new external_value(PARAM_INT, 'Total registered devices'),
        ]);
    }
}
