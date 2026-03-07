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
 * Returns the current user's role summary — whether they are a teacher/course
 * creator, and which courses they have the editing-teacher role in.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class get_user_role_summary extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([]);
    }

    public static function execute(): array {
        global $DB, $USER;

        $context = \context_system::instance();
        self::validate_context($context);

        // Editing teacher = roleid 3, Non-editing teacher = roleid 4
        // Course creator = roleid 2, Manager = roleid 1
        $sql = "SELECT DISTINCT ra.roleid, ctx.instanceid AS courseid
                  FROM {role_assignments} ra
                  JOIN {context} ctx ON ctx.id = ra.contextid
                 WHERE ra.userid = :userid
                   AND ctx.contextlevel = 50
                   AND ra.roleid IN (3, 4)";
        $records = $DB->get_records_sql($sql, ['userid' => $USER->id]);

        $is_teacher = !empty($records);
        $teacher_courseids = [];
        foreach ($records as $rec) {
            $teacher_courseids[(int)$rec->courseid] = (int)$rec->courseid;
        }
        $teacher_courseids = array_values($teacher_courseids);

        // Check for course creator role (roleid 2) or manager role (roleid 1)
        // at system level — these are site-level roles.
        $is_course_creator = $DB->record_exists_sql(
            "SELECT 1 FROM {role_assignments} ra
               JOIN {context} ctx ON ctx.id = ra.contextid
              WHERE ra.userid = :userid
                AND ra.roleid IN (1, 2)
                AND ctx.contextlevel = 10",
            ['userid' => $USER->id]
        );

        return [
            'is_teacher'        => $is_teacher,
            'is_course_creator' => $is_course_creator,
            'teacher_courseids'  => $teacher_courseids,
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'is_teacher' => new external_value(PARAM_BOOL, 'User has teacher role in at least one course'),
            'is_course_creator' => new external_value(PARAM_BOOL, 'User has course creator role'),
            'teacher_courseids' => new external_multiple_structure(
                new external_value(PARAM_INT, 'Course ID where user is teacher')
            ),
        ]);
    }
}
