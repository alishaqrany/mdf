<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Revoke (remove) a specific device for a user.
 *
 * @package    local_mdf_api
 */
class revoke_device extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'device_record_id' => new external_value(PARAM_INT, 'The device record ID to revoke'),
        ]);
    }

    public static function execute(int $device_record_id): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'device_record_id' => $device_record_id,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);

        $record = $DB->get_record('local_mdf_user_devices', ['id' => $params['device_record_id']]);
        if (!$record) {
            throw new \moodle_exception('devicenotfound', 'local_mdf_api');
        }

        // Users can revoke their own devices; admins can revoke anyone's.
        if ((int)$record->userid !== $USER->id) {
            require_capability('local/mdf_api:manageprotection', $context);
        }

        $DB->delete_records('local_mdf_user_devices', ['id' => $params['device_record_id']]);

        // Log.
        $DB->insert_record('local_mdf_protection_log', (object)[
            'userid' => (int)$record->userid,
            'action' => 'device_revoked',
            'details' => "Device '{$record->devicename}' revoked by user {$USER->id}",
            'devicename' => $record->devicename,
            'platform' => $record->platform,
            'ipaddress' => getremoteaddr(),
            'timecreated' => time(),
        ]);

        return ['success' => true];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether device was revoked'),
        ]);
    }
}
