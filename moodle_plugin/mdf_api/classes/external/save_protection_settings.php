<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Save content protection settings.
 *
 * @package    local_mdf_api
 */
class save_protection_settings extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'enabled' => new external_value(PARAM_BOOL, 'Enable content protection'),
            'prevent_screen_capture' => new external_value(PARAM_BOOL, 'Prevent screenshots'),
            'prevent_screen_recording' => new external_value(PARAM_BOOL, 'Prevent screen recording'),
            'watermark_enabled' => new external_value(PARAM_BOOL, 'Show watermark'),
            'default_max_devices' => new external_value(PARAM_INT, 'Default max devices'),
            'protected_course_ids' => new external_value(PARAM_TEXT, 'Comma-separated course IDs', VALUE_DEFAULT, ''),
            'protected_content_types' => new external_value(PARAM_TEXT, 'Comma-separated types', VALUE_DEFAULT, ''),
        ]);
    }

    public static function execute(
        bool $enabled,
        bool $prevent_screen_capture,
        bool $prevent_screen_recording,
        bool $watermark_enabled,
        int $default_max_devices,
        string $protected_course_ids = '',
        string $protected_content_types = ''
    ): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'enabled' => $enabled,
            'prevent_screen_capture' => $prevent_screen_capture,
            'prevent_screen_recording' => $prevent_screen_recording,
            'watermark_enabled' => $watermark_enabled,
            'default_max_devices' => $default_max_devices,
            'protected_course_ids' => $protected_course_ids,
            'protected_content_types' => $protected_content_types,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:manageprotection', $context);

        $now = time();
        $record = $DB->get_record('local_mdf_protection_settings', ['id' => 1]);

        $data = new \stdClass();
        $data->enabled = $params['enabled'] ? 1 : 0;
        $data->preventscreencapture = $params['prevent_screen_capture'] ? 1 : 0;
        $data->preventscreenrecording = $params['prevent_screen_recording'] ? 1 : 0;
        $data->watermarkenabled = $params['watermark_enabled'] ? 1 : 0;
        $data->defaultmaxdevices = $params['default_max_devices'];
        $data->protectedcourseids = $params['protected_course_ids'];
        $data->protectedcontenttypes = $params['protected_content_types'];
        $data->timemodified = $now;

        if ($record) {
            $data->id = $record->id;
            $DB->update_record('local_mdf_protection_settings', $data);
        } else {
            $data->timecreated = $now;
            $DB->insert_record('local_mdf_protection_settings', $data);
        }

        // Log the settings change.
        self::log_protection_event($USER->id, 'settings_changed', 'Protection settings updated', '', '', '');

        return ['success' => true];
    }

    private static function log_protection_event(int $userid, string $action, string $details,
            string $devicename, string $platform, string $ipaddress): void {
        global $DB;
        $DB->insert_record('local_mdf_protection_log', (object)[
            'userid' => $userid,
            'action' => $action,
            'details' => $details,
            'devicename' => $devicename,
            'platform' => $platform,
            'ipaddress' => $ipaddress ?: getremoteaddr(),
            'timecreated' => time(),
        ]);
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether settings were saved'),
        ]);
    }
}
