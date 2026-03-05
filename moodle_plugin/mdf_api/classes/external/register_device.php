<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Register a user device for content protection tracking.
 *
 * @package    local_mdf_api
 */
class register_device extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'device_id' => new external_value(PARAM_TEXT, 'Unique device identifier'),
            'device_name' => new external_value(PARAM_TEXT, 'Human-readable device name'),
            'platform' => new external_value(PARAM_TEXT, 'Platform (android, ios, web, windows, macos, linux)'),
            'os_version' => new external_value(PARAM_TEXT, 'OS version string', VALUE_DEFAULT, ''),
            'app_version' => new external_value(PARAM_TEXT, 'App version string', VALUE_DEFAULT, ''),
        ]);
    }

    public static function execute(
        string $device_id,
        string $device_name,
        string $platform,
        string $os_version = '',
        string $app_version = ''
    ): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'device_id' => $device_id,
            'device_name' => $device_name,
            'platform' => $platform,
            'os_version' => $os_version,
            'app_version' => $app_version,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);

        $userid = $USER->id;
        $now = time();

        // Check if device already registered for this user.
        $existing = $DB->get_record('local_mdf_user_devices', [
            'userid' => $userid,
            'deviceid' => $params['device_id'],
        ]);

        if ($existing) {
            // Update last active.
            $existing->lastactive = $now;
            $existing->devicename = $params['device_name'];
            $existing->osversion = $params['os_version'];
            $existing->appversion = $params['app_version'];
            $existing->timemodified = $now;
            $DB->update_record('local_mdf_user_devices', $existing);
            return ['success' => true, 'device_record_id' => (int)$existing->id, 'is_new' => false];
        }

        // Check device limit (admins are unlimited).
        if (!is_siteadmin($userid)) {
            $limit = self::get_user_device_limit($userid);
            $count = $DB->count_records('local_mdf_user_devices', ['userid' => $userid]);
            if ($count >= $limit) {
                // Log the exceeded attempt.
                $DB->insert_record('local_mdf_protection_log', (object)[
                    'userid' => $userid,
                    'action' => 'device_limit_exceeded',
                    'details' => "Attempted to register device '{$params['device_name']}' but limit ($limit) reached",
                    'devicename' => $params['device_name'],
                    'platform' => $params['platform'],
                    'ipaddress' => getremoteaddr(),
                    'timecreated' => $now,
                ]);
                return ['success' => false, 'device_record_id' => 0, 'is_new' => false];
            }
        }

        // Register new device.
        $record = new \stdClass();
        $record->userid = $userid;
        $record->deviceid = $params['device_id'];
        $record->devicename = $params['device_name'];
        $record->platform = $params['platform'];
        $record->osversion = $params['os_version'];
        $record->appversion = $params['app_version'];
        $record->lastactive = $now;
        $record->timecreated = $now;
        $record->timemodified = $now;

        $id = $DB->insert_record('local_mdf_user_devices', $record);

        // Log.
        $DB->insert_record('local_mdf_protection_log', (object)[
            'userid' => $userid,
            'action' => 'device_registered',
            'details' => "Registered device '{$params['device_name']}' ({$params['platform']})",
            'devicename' => $params['device_name'],
            'platform' => $params['platform'],
            'ipaddress' => getremoteaddr(),
            'timecreated' => $now,
        ]);

        return ['success' => true, 'device_record_id' => (int)$id, 'is_new' => true];
    }

    private static function get_user_device_limit(int $userid): int {
        global $DB;

        // Check per-user limit first.
        $userLimit = $DB->get_record('local_mdf_device_limits', ['userid' => $userid]);
        if ($userLimit) {
            return (int)$userLimit->maxdevices;
        }

        // Fall back to global default.
        $settings = $DB->get_record('local_mdf_protection_settings', ['id' => 1]);
        return $settings ? (int)$settings->defaultmaxdevices : 3;
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether device was registered'),
            'device_record_id' => new external_value(PARAM_INT, 'The device record ID'),
            'is_new' => new external_value(PARAM_BOOL, 'Whether this is a newly registered device'),
        ]);
    }
}
