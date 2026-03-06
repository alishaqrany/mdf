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
 * Send push notifications via Firebase Cloud Messaging V1 API.
 *
 * Uses OAuth2 service account credentials for authentication.
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

        // Get FCM V1 configuration from plugin settings.
        $service_account_json = get_config('local_mdf_api', 'fcm_service_account_json');
        $fcm_project_id = get_config('local_mdf_api', 'fcm_project_id');

        // Fallback: try legacy server key if V1 config is not set.
        $fcm_server_key = get_config('local_mdf_api', 'fcm_server_key');

        if (empty($service_account_json) && empty($fcm_server_key)) {
            throw new \moodle_exception('fcmkeynotconfigured', 'local_mdf_api');
        }

        // Determine if using V1 API.
        $use_v1 = !empty($service_account_json) && !empty($fcm_project_id);

        // Get OAuth2 access token for V1 API.
        $access_token = null;
        if ($use_v1) {
            $access_token = self::get_access_token($service_account_json);
            if (empty($access_token)) {
                throw new \moodle_exception('fcmauthfailed', 'local_mdf_api', '',
                    'Failed to obtain FCM V1 access token');
            }
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
                if ($use_v1) {
                    $fcm_result = self::send_fcm_v1_message(
                        $access_token,
                        $fcm_project_id,
                        $token_record->token,
                        $params['title'],
                        $params['body'],
                        $params['data']
                    );
                } else {
                    $fcm_result = self::send_fcm_legacy_message(
                        $fcm_server_key,
                        $token_record->token,
                        $params['title'],
                        $params['body'],
                        $params['data']
                    );
                }

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
     * Obtain an OAuth2 access token from the FCM service account JSON.
     *
     * Uses JWT (RS256) to request a token from Google's OAuth2 endpoint.
     *
     * @param string $service_account_json Raw JSON of the service account key
     * @return string|null Access token or null on failure
     */
    private static function get_access_token(string $service_account_json): ?string {
        // Check cache first.
        $cache = \cache::make('local_mdf_api', 'fcm_tokens');
        $cached = $cache->get('access_token');
        if ($cached && !empty($cached['token']) && $cached['expires'] > time() + 60) {
            return $cached['token'];
        }

        $sa = json_decode($service_account_json, true);
        if (!$sa || empty($sa['private_key']) || empty($sa['client_email']) || empty($sa['token_uri'])) {
            return null;
        }

        $now = time();
        $header = self::base64url_encode(json_encode([
            'alg' => 'RS256',
            'typ' => 'JWT',
        ]));
        $claims = self::base64url_encode(json_encode([
            'iss'   => $sa['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud'   => $sa['token_uri'],
            'iat'   => $now,
            'exp'   => $now + 3600,
        ]));

        $signing_input = "$header.$claims";
        $private_key = openssl_pkey_get_private($sa['private_key']);
        if (!$private_key) {
            return null;
        }

        $signature = '';
        if (!openssl_sign($signing_input, $signature, $private_key, OPENSSL_ALGO_SHA256)) {
            return null;
        }

        $jwt = $signing_input . '.' . self::base64url_encode($signature);

        // Exchange JWT for access token.
        $ch = curl_init($sa['token_uri']);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POSTFIELDS     => http_build_query([
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion'  => $jwt,
            ]),
            CURLOPT_HTTPHEADER     => ['Content-Type: application/x-www-form-urlencoded'],
            CURLOPT_TIMEOUT        => 10,
            CURLOPT_CONNECTTIMEOUT => 5,
        ]);

        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($http_code !== 200 || empty($response)) {
            return null;
        }

        $data = json_decode($response, true);
        if (empty($data['access_token'])) {
            return null;
        }

        // Cache the token.
        $cache->set('access_token', [
            'token'   => $data['access_token'],
            'expires' => $now + ($data['expires_in'] ?? 3600),
        ]);

        return $data['access_token'];
    }

    /**
     * Base64url encode (no padding).
     */
    private static function base64url_encode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Send a single FCM message using the V1 HTTP API.
     *
     * @param string $access_token OAuth2 Bearer token
     * @param string $project_id   Firebase project ID
     * @param string $token        Device FCM token
     * @param string $title        Notification title
     * @param string $body         Notification body
     * @param string $data         JSON data payload
     * @return array ['success' => bool, 'invalid_token' => bool, 'message' => string, 'response' => mixed]
     */
    private static function send_fcm_v1_message(
        string $access_token,
        string $project_id,
        string $token,
        string $title,
        string $body,
        string $data
    ): array {
        $url = "https://fcm.googleapis.com/v1/projects/{$project_id}/messages:send";

        $payload = [
            'message' => [
                'token' => $token,
                'notification' => [
                    'title' => $title,
                    'body'  => $body,
                ],
                'data' => json_decode($data, true) ?? [],
                'android' => [
                    'priority' => 'high',
                    'notification' => [
                        'sound' => 'default',
                        'channel_id' => 'mdf_notifications',
                    ],
                ],
                'apns' => [
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                            'badge' => 1,
                        ],
                    ],
                ],
            ],
        ];

        $ch = curl_init($url);
        $json = json_encode($payload);
        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => [
                'Authorization: Bearer ' . $access_token,
                'Content-Type: application/json',
                'Content-Length: ' . strlen($json),
            ],
            CURLOPT_POSTFIELDS     => $json,
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

        if ($http_code === 200) {
            return [
                'success'       => true,
                'invalid_token' => false,
                'message'       => 'OK',
                'response'      => $response,
            ];
        }

        // Handle errors.
        $invalid = false;
        $message = 'FCM V1 error (HTTP ' . $http_code . ')';

        if (!empty($response['error'])) {
            $error_status = $response['error']['status'] ?? '';
            $error_message = $response['error']['message'] ?? $message;
            $message = $error_message;

            // These error codes indicate the token is invalid.
            $invalid = in_array($error_status, [
                'NOT_FOUND',
                'INVALID_ARGUMENT',
                'UNREGISTERED',
            ]);

            // Also check for specific FCM error details.
            if (!empty($response['error']['details'])) {
                foreach ($response['error']['details'] as $detail) {
                    if (isset($detail['errorCode'])) {
                        $invalid = $invalid || in_array($detail['errorCode'], [
                            'UNREGISTERED',
                            'INVALID_ARGUMENT',
                        ]);
                    }
                }
            }
        }

        return [
            'success'       => false,
            'invalid_token' => $invalid,
            'message'       => $message,
            'response'      => $response,
        ];
    }

    /**
     * Send a single FCM message using the legacy HTTP protocol (fallback).
     *
     * @deprecated Use FCM V1 API instead. This method is kept for backward compatibility.
     *
     * @param string $server_key FCM server key
     * @param string $token      Device FCM token
     * @param string $title      Notification title
     * @param string $body       Notification body
     * @param string $data       JSON data payload
     * @return array ['success' => bool, 'invalid_token' => bool, 'message' => string, 'response' => mixed]
     */
    private static function send_fcm_legacy_message(
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
