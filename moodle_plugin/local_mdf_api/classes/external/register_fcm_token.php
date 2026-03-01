<?php
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Moodle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Moodle.  If not, see <http://www.gnu.org/licenses/>.

namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Register or update a Firebase Cloud Messaging token for the current user.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class register_fcm_token extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'token'      => new external_value(PARAM_RAW, 'FCM device token'),
            'platform'   => new external_value(PARAM_ALPHA,
                'Device platform: android or ios'),
            'devicename' => new external_value(PARAM_TEXT,
                'Human-readable device name', VALUE_DEFAULT, ''),
        ]);
    }

    public static function execute(
        string $token,
        string $platform,
        string $devicename = ''
    ): array {
        global $DB, $USER;

        $context = \context_system::instance();
        self::validate_context($context);
        // No special capability needed — any authenticated user can register.

        $params = self::validate_parameters(self::execute_parameters(), [
            'token'      => $token,
            'platform'   => $platform,
            'devicename' => $devicename,
        ]);

        // Validate platform.
        $allowed_platforms = ['android', 'ios'];
        if (!in_array(strtolower($params['platform']), $allowed_platforms)) {
            throw new \invalid_parameter_exception(
                'platform must be one of: ' . implode(', ', $allowed_platforms)
            );
        }

        // Validate token length.
        $token = trim($params['token']);
        if (strlen($token) < 10 || strlen($token) > 512) {
            throw new \invalid_parameter_exception(
                'token must be between 10 and 512 characters'
            );
        }

        $now = time();

        // Check if this token is already registered (for any user).
        $existing = $DB->get_record('local_mdf_fcm_tokens', ['token' => $token]);

        if ($existing) {
            // Update existing record — reassign to current user if different.
            $existing->userid       = $USER->id;
            $existing->platform     = strtolower($params['platform']);
            $existing->devicename   = $params['devicename'];
            $existing->timemodified = $now;
            $DB->update_record('local_mdf_fcm_tokens', $existing);

            return [
                'success' => 1,
                'action'  => 'updated',
                'tokenid' => (int)$existing->id,
            ];
        }

        // Insert new token.
        $record = new \stdClass();
        $record->userid       = $USER->id;
        $record->token        = $token;
        $record->platform     = strtolower($params['platform']);
        $record->devicename   = $params['devicename'];
        $record->timecreated  = $now;
        $record->timemodified = $now;

        $id = $DB->insert_record('local_mdf_fcm_tokens', $record);

        return [
            'success' => 1,
            'action'  => 'created',
            'tokenid' => (int)$id,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_INT, 'Success flag (1/0)'),
            'action'  => new external_value(PARAM_TEXT, 'Action taken: created or updated'),
            'tokenid' => new external_value(PARAM_INT, 'Token record ID'),
        ]);
    }
}
