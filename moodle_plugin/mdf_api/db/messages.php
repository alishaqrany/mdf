<?php
// This file is part of Moodle - http://moodle.org/
//
// Message provider definitions for local_mdf_api.

defined('MOODLE_INTERNAL') || die();

if (!function_exists('local_mdf_api_message_constant')) {
    /**
     * Safely resolve optional Moodle message constants across versions.
     *
     * @param string $name
     * @param int $fallback
     * @return int
     */
    function local_mdf_api_message_constant(string $name, int $fallback = 0): int {
        return defined($name) ? (int) constant($name) : $fallback;
    }
}

$permitted = local_mdf_api_message_constant('MESSAGE_PERMITTED', 1);
$defaultloggedin = local_mdf_api_message_constant(
    'MESSAGE_DEFAULT_LOGGEDIN',
    local_mdf_api_message_constant('MESSAGE_DEFAULT_ENABLED', 0)
);
$defaultloggedoff = local_mdf_api_message_constant('MESSAGE_DEFAULT_LOGGEDOFF', 0);

$messageproviders = [
    // Admin-originated notification sent via the notification admin panel.
    'admin_notification' => [
        'defaults' => [
            'popup'  => $permitted + $defaultloggedin + $defaultloggedoff,
            'email'  => $permitted + $defaultloggedin + $defaultloggedoff,
        ],
    ],
];
