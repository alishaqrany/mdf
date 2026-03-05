<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Get device limit for a specific user.
 *
 * @package    local_mdf_api
 */
class get_user_device_limit extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'Target user ID (0 = current user)', VALUE_DEFAULT, 0),
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

        // Non-admins can only check their own limit.
        if ($targetUserId !== $USER->id) {
            require_capability('local/mdf_api:manageprotection', $context);
        }

        $is_admin = is_siteadmin($targetUserId);

        if ($is_admin) {
            return [
                'userid' => $targetUserId,
                'max_devices' => 999,
                'is_custom' => false,
                'is_admin' => true,
            ];
        }

        $userLimit = $DB->get_record('local_mdf_device_limits', ['userid' => $targetUserId]);
        if ($userLimit) {
            return [
                'userid' => $targetUserId,
                'max_devices' => (int)$userLimit->maxdevices,
                'is_custom' => true,
                'is_admin' => false,
            ];
        }

        // Fall back to global default.
        $settings = $DB->get_record('local_mdf_protection_settings', ['id' => 1]);
        $defaultMax = $settings ? (int)$settings->defaultmaxdevices : 3;

        return [
            'userid' => $targetUserId,
            'max_devices' => $defaultMax,
            'is_custom' => false,
            'is_admin' => false,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'userid' => new external_value(PARAM_INT, 'User ID'),
            'max_devices' => new external_value(PARAM_INT, 'Maximum devices allowed'),
            'is_custom' => new external_value(PARAM_BOOL, 'Whether a custom limit is set'),
            'is_admin' => new external_value(PARAM_BOOL, 'Whether user is admin (unlimited)'),
        ]);
    }
}
