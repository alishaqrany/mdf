<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Validate whether the current device is allowed for this user.
 *
 * @package    local_mdf_api
 */
class validate_device_access extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'device_id' => new external_value(PARAM_TEXT, 'Unique device identifier'),
        ]);
    }

    public static function execute(string $device_id): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'device_id' => $device_id,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = $USER->id;

        // Admins always have access.
        if (is_siteadmin($userid)) {
            return ['allowed' => true, 'reason' => 'admin'];
        }

        // Check if protection is even enabled.
        $settings = $DB->get_record('local_mdf_protection_settings', ['id' => 1]);
        if (!$settings || !$settings->enabled) {
            return ['allowed' => true, 'reason' => 'protection_disabled'];
        }

        // Check if device is registered.
        $device = $DB->get_record('local_mdf_user_devices', [
            'userid' => $userid,
            'deviceid' => $params['device_id'],
        ]);

        if ($device) {
            // Update last active.
            $device->lastactive = time();
            $DB->update_record('local_mdf_user_devices', $device);
            return ['allowed' => true, 'reason' => 'device_registered'];
        }

        // Device not registered — check if there's room.
        $limit = self::get_user_device_limit($userid);
        $count = $DB->count_records('local_mdf_user_devices', ['userid' => $userid]);

        if ($count < $limit) {
            return ['allowed' => true, 'reason' => 'can_register'];
        }

        // Log denied access.
        $DB->insert_record('local_mdf_protection_log', (object)[
            'userid' => $userid,
            'action' => 'access_denied',
            'details' => "Device access denied - limit reached ($count/$limit)",
            'devicename' => '',
            'platform' => '',
            'ipaddress' => getremoteaddr(),
            'timecreated' => time(),
        ]);

        return ['allowed' => false, 'reason' => 'device_limit_reached'];
    }

    private static function get_user_device_limit(int $userid): int {
        global $DB;

        $userLimit = $DB->get_record('local_mdf_device_limits', ['userid' => $userid]);
        if ($userLimit) {
            return (int)$userLimit->maxdevices;
        }

        $settings = $DB->get_record('local_mdf_protection_settings', ['id' => 1]);
        return $settings ? (int)$settings->defaultmaxdevices : 3;
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'allowed' => new external_value(PARAM_BOOL, 'Whether access is allowed'),
            'reason' => new external_value(PARAM_TEXT, 'Reason code'),
        ]);
    }
}
