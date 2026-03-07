<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_multiple_structure;
use core_external\external_value;

/**
 * Send Moodle native notifications to users (appears in their notification popup).
 * Optionally also sends FCM push notifications via the V1 API.
 *
 * @package    local_mdf_api
 */
class send_moodle_notification extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userids'      => new external_multiple_structure(
                new external_value(PARAM_INT, 'User ID'),
                'Array of target user IDs'
            ),
            'subject'      => new external_value(PARAM_TEXT, 'Notification subject'),
            'fullmessage'  => new external_value(PARAM_RAW, 'Full message (HTML)'),
            'smallmessage' => new external_value(PARAM_TEXT, 'Short message for popup', VALUE_DEFAULT, ''),
            'contexturl'   => new external_value(PARAM_URL, 'Context URL to link to', VALUE_DEFAULT, ''),
            'contexturlname' => new external_value(PARAM_TEXT, 'Context URL display name', VALUE_DEFAULT, ''),
        ]);
    }

    public static function execute(
        array $userids,
        string $subject,
        string $fullmessage,
        string $smallmessage = '',
        string $contexturl = '',
        string $contexturlname = ''
    ): array {
        global $USER;

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:sendnotification', $context);

        $params = self::validate_parameters(self::execute_parameters(), [
            'userids'        => $userids,
            'subject'        => $subject,
            'fullmessage'    => $fullmessage,
            'smallmessage'   => $smallmessage,
            'contexturl'     => $contexturl,
            'contexturlname' => $contexturlname,
        ]);

        if (empty($params['smallmessage'])) {
            $params['smallmessage'] = strip_tags($params['fullmessage']);
            if (strlen($params['smallmessage']) > 300) {
                $params['smallmessage'] = substr($params['smallmessage'], 0, 297) . '...';
            }
        }

        $total_sent = 0;
        $total_failed = 0;
        $results = [];

        foreach ($params['userids'] as $userid) {
            try {
                $userto = \core_user::get_user($userid);
                if (!$userto || isguestuser($userto) || $userto->deleted) {
                    $total_failed++;
                    $results[] = [
                        'userid'  => $userid,
                        'status'  => 'failed',
                        'message' => 'User not found or invalid (id=' . $userid . ')',
                    ];
                    continue;
                }

                $message = new \core\message\message();
                $message->component = 'local_mdf_api';
                $message->name = 'admin_notification';
                $message->userfrom = \core_user::get_noreply_user();
                $message->userto = $userto;
                $message->subject = $params['subject'];
                $message->fullmessage = strip_tags($params['fullmessage']);
                $message->fullmessageformat = FORMAT_HTML;
                $message->fullmessagehtml = $params['fullmessage'];
                $message->smallmessage = $params['smallmessage'];
                $message->notification = 1;
                $message->courseid = SITEID;

                if (!empty($params['contexturl'])) {
                    $message->contexturl = $params['contexturl'];
                    $message->contexturlname = $params['contexturlname'] ?: $params['subject'];
                }

                $messageid = message_send($message);

                if ($messageid) {
                    $total_sent++;
                    $results[] = [
                        'userid'  => $userid,
                        'status'  => 'sent',
                        'message' => 'OK',
                    ];
                } else {
                    $total_failed++;
                    $results[] = [
                        'userid'  => $userid,
                        'status'  => 'failed',
                        'message' => 'message_send returned false — check notification preferences',
                    ];
                }
            } catch (\Throwable $e) {
                $total_failed++;
                $results[] = [
                    'userid'  => $userid,
                    'status'  => 'failed',
                    'message' => $e->getMessage(),
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
                    'userid'  => new external_value(PARAM_INT, 'Target user ID'),
                    'status'  => new external_value(PARAM_TEXT, 'Status: sent or failed'),
                    'message' => new external_value(PARAM_TEXT, 'Detail message'),
                ])
            ),
        ]);
    }
}
