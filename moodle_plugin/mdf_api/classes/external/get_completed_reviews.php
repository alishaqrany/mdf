<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_completed_reviews extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'userid' => new external_value(PARAM_INT, 'Reviewer user ID (0 = current)', VALUE_DEFAULT, 0),
        ]);
    }

    public static function execute(int $userid = 0): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), ['userid' => $userid]);
        $userid = $params['userid'] ?: (int)$USER->id;

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:viewpeerreviews', $context);

        $sql = "SELECT a.id as assessmentid, a.submissionid, a.reviewerid, a.grade,
                       a.feedbackauthor, a.timecreated as timereviewed,
                       s.id as sid, s.workshopid, s.authorid, s.timecreated as timesubmitted,
                       s.content, s.title as stitle,
                       w.id as wid, w.name as workshopname, w.course as courseid, w.grade as maxgrade
                FROM {workshop_assessments} a
                JOIN {workshop_submissions} s ON s.id = a.submissionid
                JOIN {workshop} w ON w.id = s.workshopid
                WHERE a.reviewerid = :userid
                  AND a.grade IS NOT NULL AND a.grade >= 0
                ORDER BY a.timecreated DESC";

        $records = $DB->get_records_sql($sql, ['userid' => $userid]);

        $result = [];
        foreach ($records as $r) {
            $result[] = get_pending_reviews::format_review($r, 'completed');
        }

        return ['reviews' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'reviews' => new external_multiple_structure(
                get_pending_reviews::review_structure()
            ),
        ]);
    }
}
