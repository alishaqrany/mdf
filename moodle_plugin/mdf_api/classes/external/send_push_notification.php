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
use core_external\external_multiple_structure;
use core_external\external_value;

/**
 * Send push notifications via Firebase Cloud Messaging.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class send_push_notification extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userids' => new external_multiple_structure(
                new external_value(PARAM_INT, 'User ID'),
                'Array of target user IDs'
            ),
            'title' => new external_value(PARAM_TEXT, 'Notification title'),
            'body'  => new external_value(PARAM_TEXT, 'Notification body'),
            'data'  => new external_value(PARAM_RAW,
                'Optional JSON data payload', VALUE_DEFAULT, '{}'),
        ]);
    }

    public static function execute(
        array $userids,
        string $title,
        string $body,
        string $data = '{}'
    ): array {
        global $DB, $USER;

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:sendnotification', $context);

        $params = self::validate_parameters(self::execute_parameters(), [
            'userids' => $userids,
            'title'   => $title,
            'body'    => $body,
            'data'    => $data,
        ]);

        // Validate JSON data.
        $data_decoded = json_decode($params['data']);
        if ($data_decoded === null && $params['data'] !== '{}') {
            throw new \invalid_parameter_exception('data must be valid JSON');
        }

        // Get FCM server key from plugin settings.
        $fcm_server_key = get_config('local_mdf_api', 'fcm_server_key');
        if (empty($fcm_server_key)) {
            throw new \moodle_exception('fcmkeynotconfigured', 'local_mdf_api');
        }

        $total_sent   = 0;
        $total_failed = 0;
        $results      = [];

        foreach ($params['userids'] as $userid) {
            // Get all FCM tokens for this user.
            $tokens = $DB->get_records('local_mdf_fcm_tokens', [
                'userid' => $userid,
            ]);

            if (empty($tokens)) {
                $results[] = [
                    'userid'  => $userid,
                    'status'  => 'no_token',
                    'message' => get_string('notokenfound', 'local_mdf_api'),
                ];
                $total_failed++;
                continue;
            }

            foreach ($tokens as $token_record) {
                $fcm_result = self::send_fcm_message(
                    $fcm_server_key,
                    $token_record->token,
                    $params['title'],
                    $params['body'],
                    $params['data']
                );

                $status = $fcm_result['success'] ? 'sent' : 'failed';

                // Log to push_log table.
                $log = new \stdClass();
                $log->userid      = $userid;
                $log->senderid    = $USER->id;
                $log->title       = $params['title'];
                $log->body        = $params['body'];
                $log->data        = $params['data'];
                $log->status      = $status;
                $log->fcm_response = json_encode($fcm_result['response'] ?? []);
                $log->timecreated  = time();
                $DB->insert_record('local_mdf_push_log', $log);

                if ($fcm_result['success']) {
                    $total_sent++;
                } else {
                    $total_failed++;

                    // If token is invalid, remove it.
                    if ($fcm_result['invalid_token']) {
                        $DB->delete_records('local_mdf_fcm_tokens', [
                            'id' => $token_record->id,
                        ]);
                    }
                }

                $results[] = [
                    'userid'  => $userid,
                    'status'  => $status,
                    'message' => $fcm_result['message'] ?? '',
                ];
            }
        }

        return [
            'total_sent'   => $total_sent,
            'total_failed' => $total_failed,
            'results'      => $results,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'total_sent'   => new external_value(PARAM_INT, 'Total notifications sent'),
            'total_failed' => new external_value(PARAM_INT, 'Total failures'),
            'results'      => new external_multiple_structure(
                new external_single_structure([
                    'userid'  => new external_value(PARAM_INT,  'Target user ID'),
                    'status'  => new external_value(PARAM_TEXT, 'Status: sent, failed, no_token'),
                    'message' => new external_value(PARAM_TEXT, 'Detail message'),
                ])
            ),
        ]);
    }

    /**
     * Send a single FCM message using the legacy HTTP protocol.
     *
     * @param string $server_key FCM server key
     * @param string $token      Device FCM token
     * @param string $title      Notification title
     * @param string $body       Notification body
     * @param string $data       JSON data payload
     * @return array ['success' => bool, 'invalid_token' => bool, 'message' => string, 'response' => mixed]
     */
    private static function send_fcm_message(
        string $server_key,
        string $token,
        string $title,
        string $body,
        string $data
    ): array {
        $payload = [
            'to' => $token,
            'notification' => [
                'title' => $title,
                'body'  => $body,
                'sound' => 'default',
            ],
            'data' => json_decode($data, true) ?? [],
            'priority' => 'high',
        ];

        $ch = curl_init('https://fcm.googleapis.com/fcm/send');
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => [
                'Authorization: key=' . $server_key,
                'Content-Type: application/json',
            ],
            CURLOPT_POSTFIELDS     => json_encode($payload),
            CURLOPT_TIMEOUT        => 10,
            CURLOPT_CONNECTTIMEOUT => 5,
        ]);

        $response_body = curl_exec($ch);
        $http_code     = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curl_error    = curl_error($ch);
        curl_close($ch);

        if (!empty($curl_error)) {
            return [
                'success'       => false,
                'invalid_token' => false,
                'message'       => 'cURL error: ' . $curl_error,
                'response'      => null,
            ];
        }

        $response = json_decode($response_body, true);

        if ($http_code !== 200 || empty($response['success'])) {
            $invalid = false;
            $message = 'FCM error (HTTP ' . $http_code . ')';

            if (!empty($response['results'][0]['error'])) {
                $error = $response['results'][0]['error'];
                $message = $error;
                // These errors indicate the token is no longer valid.
                $invalid = in_array($error, [
                    'NotRegistered',
                    'InvalidRegistration',
                    'MismatchSenderId',
                ]);
            }

            return [
                'success'       => false,
                'invalid_token' => $invalid,
                'message'       => $message,
                'response'      => $response,
            ];
        }

        return [
            'success'       => true,
            'invalid_token' => false,
            'message'       => 'OK',
            'response'      => $response,
        ];
    }
}
