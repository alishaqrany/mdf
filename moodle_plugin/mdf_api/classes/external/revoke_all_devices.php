<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Revoke all devices for a user.
 *
 * @package    local_mdf_api
 */
class revoke_all_devices extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'User ID whose devices to revoke'),
        ]);
    }

    public static function execute(int $userid): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'userid' => $userid,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:manageprotection', $context);

        $count = $DB->count_records('local_mdf_user_devices', ['userid' => $params['userid']]);
        $DB->delete_records('local_mdf_user_devices', ['userid' => $params['userid']]);

        // Log.
        $DB->insert_record('local_mdf_protection_log', (object)[
            'userid' => $params['userid'],
            'action' => 'device_revoked',
            'details' => "All devices ($count) revoked by admin {$USER->id}",
            'devicename' => '',
            'platform' => '',
            'ipaddress' => getremoteaddr(),
            'timecreated' => time(),
        ]);

        return ['success' => true, 'count' => $count];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether devices were revoked'),
            'count' => new external_value(PARAM_INT, 'Number of devices revoked'),
        ]);
    }
}
