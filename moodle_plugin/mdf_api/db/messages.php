<?php
// This file is part of Moodle - http://moodle.org/
//
// Message provider definitions for local_mdf_api.

defined('MOODLE_INTERNAL') || die();

$messageproviders = [
    // Admin-originated notification sent via the notification admin panel.
    'admin_notification' => [
        'defaults' => [
            'popup'  => MESSAGE_PERMITTED + MESSAGE_DEFAULT_LOGGEDIN + MESSAGE_DEFAULT_LOGGEDOFF,
            'email'  => MESSAGE_PERMITTED,
        ],
    ],
];
