<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Get content protection settings.
 *
 * @package    local_mdf_api
 */
class get_protection_settings extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([]);
    }

    public static function execute(): array {
        global $DB;

        $context = \context_system::instance();
        self::validate_context($context);

        // Any authenticated user can read protection settings (needed to apply them).
        $record = $DB->get_record('local_mdf_protection_settings', ['id' => 1]);

        if (!$record) {
            return [
                'enabled' => false,
                'prevent_screen_capture' => false,
                'prevent_screen_recording' => false,
                'watermark_enabled' => false,
                'default_max_devices' => 3,
                'protected_course_ids' => '',
                'protected_content_types' => '',
            ];
        }

        return [
            'enabled' => (bool)$record->enabled,
            'prevent_screen_capture' => (bool)$record->preventscreencapture,
            'prevent_screen_recording' => (bool)$record->preventscreenrecording,
            'watermark_enabled' => (bool)$record->watermarkenabled,
            'default_max_devices' => (int)$record->defaultmaxdevices,
            'protected_course_ids' => $record->protectedcourseids ?? '',
            'protected_content_types' => $record->protectedcontenttypes ?? '',
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'enabled' => new external_value(PARAM_BOOL, 'Whether content protection is enabled'),
            'prevent_screen_capture' => new external_value(PARAM_BOOL, 'Prevent screenshots'),
            'prevent_screen_recording' => new external_value(PARAM_BOOL, 'Prevent screen recording'),
            'watermark_enabled' => new external_value(PARAM_BOOL, 'Show watermark on content'),
            'default_max_devices' => new external_value(PARAM_INT, 'Default max devices per user'),
            'protected_course_ids' => new external_value(PARAM_TEXT, 'Comma-separated course IDs (empty=all)'),
            'protected_content_types' => new external_value(PARAM_TEXT, 'Comma-separated content types (empty=all)'),
        ]);
    }
}
