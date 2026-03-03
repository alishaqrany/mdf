<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class get_review_detail extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'reviewid' => new external_value(PARAM_INT, 'Assessment ID'),
        ]);
    }

    public static function execute(int $reviewid): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), ['reviewid' => $reviewid]);

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
                WHERE a.id = :aid";

        $r = $DB->get_record_sql($sql, ['aid' => $params['reviewid']]);
        if (!$r) {
            throw new \moodle_exception('reviewnotfound', 'local_mdf_api');
        }

        $status = (!empty($r->grade) && (float)$r->grade >= 0) ? 'completed' : 'pending';
        return get_pending_reviews::format_review($r, $status);
    }

    public static function execute_returns(): external_single_structure {
        return get_pending_reviews::review_structure();
    }
}
