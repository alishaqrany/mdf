<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class create_study_group extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'name'        => new external_value(PARAM_TEXT, 'Group name'),
            'courseid'    => new external_value(PARAM_INT, 'Course ID'),
            'description' => new external_value(PARAM_RAW, 'Description', VALUE_DEFAULT, ''),
            'ispublic'    => new external_value(PARAM_INT, '1 for public, 0 for private', VALUE_DEFAULT, 1),
            'maxmembers'  => new external_value(PARAM_INT, 'Max members', VALUE_DEFAULT, 30),
        ]);
    }

    public static function execute(string $name, int $courseid, string $description = '',
                                    int $ispublic = 1, int $maxmembers = 30): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'name' => $name, 'courseid' => $courseid, 'description' => $description,
            'ispublic' => $ispublic, 'maxmembers' => $maxmembers,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:managestudygroups', $context);

        $now = time();
        $userid = (int)$USER->id;

        // Verify course exists.
        $DB->get_record('course', ['id' => $params['courseid']], 'id', MUST_EXIST);

        $group = new \stdClass();
        $group->name        = $params['name'];
        $group->description = $params['description'];
        $group->courseid    = $params['courseid'];
        $group->createdby   = $userid;
        $group->imageurl    = '';
        $group->ispublic    = $params['ispublic'];
        $group->maxmembers  = $params['maxmembers'];
        $group->timecreated = $now;
        $group->timemodified = $now;
        $group->id = $DB->insert_record('local_mdf_study_groups', $group);

        // Add creator as admin member.
        $member = new \stdClass();
        $member->groupid    = $group->id;
        $member->userid     = $userid;
        $member->role       = 'admin';
        $member->timejoined = $now;
        $DB->insert_record('local_mdf_group_members', $member);

        $creator = $DB->get_record('user', ['id' => $userid], 'id, firstname, lastname');
        $course = $DB->get_record('course', ['id' => $group->courseid], 'id, fullname');

        return [
            'id'          => (int)$group->id,
            'name'        => $group->name,
            'description' => $group->description,
            'courseid'    => (int)$group->courseid,
            'coursename'  => $course ? $course->fullname : '',
            'createdby'   => $userid,
            'creatorname' => $creator ? trim($creator->firstname . ' ' . $creator->lastname) : '',
            'imageurl'    => '',
            'ispublic'    => (int)$group->ispublic,
            'membercount' => 1,
            'maxmembers'  => (int)$group->maxmembers,
            'timecreated' => (int)$group->timecreated,
            'userrole'    => 'admin',
        ];
    }

    public static function execute_returns(): external_single_structure {
        return get_study_groups::group_structure();
    }
}
