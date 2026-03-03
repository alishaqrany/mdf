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

/**
 * Event observers for local_mdf_api — triggers push notifications on key events.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

$observers = [
    // Fires when a user is enrolled in a course.
    [
        'eventname' => '\core\event\user_enrolment_created',
        'callback'  => 'local_mdf_api\observer::on_user_enrolled',
    ],
    // Fires when a course is completed.
    [
        'eventname' => '\core\event\course_completed',
        'callback'  => 'local_mdf_api\observer::on_course_completed',
    ],
    // Fires when an assignment is submitted.
    [
        'eventname' => '\mod_assign\event\assessable_submitted',
        'callback'  => 'local_mdf_api\observer::on_assignment_submitted',
    ],
    // Fires when a grade is updated.
    [
        'eventname' => '\core\event\user_graded',
        'callback'  => 'local_mdf_api\observer::on_user_graded',
    ],
    // Fires when a new forum post is created.
    [
        'eventname' => '\mod_forum\event\post_created',
        'callback'  => 'local_mdf_api\observer::on_forum_post_created',
    ],
];
