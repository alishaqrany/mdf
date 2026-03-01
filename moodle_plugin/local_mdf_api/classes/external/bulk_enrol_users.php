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
require_once($CFG->libdir . '/enrollib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_multiple_structure;
use core_external\external_value;

/**
 * Bulk enroll users into a course.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class bulk_enrol_users extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'courseid' => new external_value(PARAM_INT, 'Course ID to enrol into'),
            'userids'  => new external_multiple_structure(
                new external_value(PARAM_INT, 'User ID'),
                'Array of user IDs to enrol'
            ),
            'roleid'   => new external_value(PARAM_INT,
                'Role ID (5=student by default)', VALUE_DEFAULT, 5),
            'timestart' => new external_value(PARAM_INT,
                'Enrollment start time (0 for now)', VALUE_DEFAULT, 0),
            'timeend'   => new external_value(PARAM_INT,
                'Enrollment end time (0 for unlimited)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(
        int $courseid,
        array $userids,
        int $roleid = 5,
        int $timestart = 0,
        int $timeend = 0
    ): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'courseid'  => $courseid,
            'userids'   => $userids,
            'roleid'    => $roleid,
            'timestart' => $timestart,
            'timeend'   => $timeend,
        ]);

        $courseid  = $params['courseid'];
        $userids   = $params['userids'];
        $roleid    = $params['roleid'];
        $timestart = $params['timestart'];
        $timeend   = $params['timeend'];

        // Validate course exists.
        $course = $DB->get_record('course', ['id' => $courseid], '*', MUST_EXIST);
        $context = \context_course::instance($courseid);
        self::validate_context($context);
        require_capability('local/mdf_api:bulkenrol', $context);

        // Get manual enrolment plugin.
        $enrol = enrol_get_plugin('manual');
        if (!$enrol) {
            throw new \moodle_exception('enrolpluginnotinstalled', 'enrol', '', 'manual');
        }

        // Get instance for course.
        $instances = $DB->get_records('enrol', [
            'courseid' => $courseid,
            'enrol' => 'manual',
            'status' => ENROL_INSTANCE_ENABLED,
        ]);
        $instance = reset($instances);

        if (!$instance) {
            // Create manual enrolment instance.
            $instance_id = $enrol->add_instance($course);
            $instance = $DB->get_record('enrol', ['id' => $instance_id]);
        }

        $success = [];
        $failed  = [];

        foreach ($userids as $userid) {
            try {
                // Check user exists.
                $user = $DB->get_record('user', ['id' => $userid, 'deleted' => 0]);
                if (!$user) {
                    $failed[] = [
                        'userid' => $userid,
                        'reason' => get_string('usernotfound', 'local_mdf_api'),
                    ];
                    continue;
                }

                // Check if already enrolled.
                if (is_enrolled($context, $userid)) {
                    $failed[] = [
                        'userid' => $userid,
                        'reason' => get_string('useralreadyenrolled', 'local_mdf_api'),
                    ];
                    continue;
                }

                // Enrol user.
                $enrol->enrol_user($instance, $userid, $roleid, $timestart, $timeend);

                $success[] = [
                    'userid'   => $userid,
                    'fullname' => fullname($user),
                ];
            } catch (\Exception $e) {
                $failed[] = [
                    'userid' => $userid,
                    'reason' => $e->getMessage(),
                ];
            }
        }

        return [
            'total_requested' => count($userids),
            'total_success'   => count($success),
            'total_failed'    => count($failed),
            'success'         => $success,
            'failed'          => $failed,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'total_requested' => new external_value(PARAM_INT, 'Total users requested'),
            'total_success'   => new external_value(PARAM_INT, 'Successfully enrolled'),
            'total_failed'    => new external_value(PARAM_INT, 'Failed to enrol'),
            'success' => new external_multiple_structure(
                new external_single_structure([
                    'userid'   => new external_value(PARAM_INT,  'User ID'),
                    'fullname' => new external_value(PARAM_TEXT, 'User full name'),
                ])
            ),
            'failed' => new external_multiple_structure(
                new external_single_structure([
                    'userid' => new external_value(PARAM_INT,  'User ID'),
                    'reason' => new external_value(PARAM_TEXT, 'Failure reason'),
                ])
            ),
        ]);
    }
}
