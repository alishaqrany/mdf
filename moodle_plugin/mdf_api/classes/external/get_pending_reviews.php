<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_pending_reviews extends external_api {

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

        // Get assessments assigned to this reviewer that are not yet complete.
        $sql = "SELECT a.id as assessmentid, a.submissionid, a.reviewerid, a.grade,
                       a.feedbackauthor, a.timecreated as timereviewed,
                       s.id as sid, s.workshopid, s.authorid, s.timecreated as timesubmitted,
                       s.content, s.title as stitle,
                       w.id as wid, w.name as workshopname, w.course as courseid, w.grade as maxgrade
                FROM {workshop_assessments} a
                JOIN {workshop_submissions} s ON s.id = a.submissionid
                JOIN {workshop} w ON w.id = s.workshopid
                WHERE a.reviewerid = :userid
                  AND (a.grade IS NULL OR a.grade < 0)
                ORDER BY s.timecreated DESC";

        $records = $DB->get_records_sql($sql, ['userid' => $userid]);

        $result = [];
        foreach ($records as $r) {
            $result[] = self::format_review($r, 'pending');
        }

        return ['reviews' => $result];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'reviews' => new external_multiple_structure(self::review_structure()),
        ]);
    }

    public static function review_structure(): external_single_structure {
        return new external_single_structure([
            'id'                     => new external_value(PARAM_INT, 'Assessment ID'),
            'assessmentid'           => new external_value(PARAM_INT, 'Assessment ID (alias)'),
            'workshopid'             => new external_value(PARAM_INT, 'Workshop ID'),
            'workshopname'           => new external_value(PARAM_TEXT, 'Workshop name'),
            'courseid'               => new external_value(PARAM_INT, 'Course ID'),
            'coursename'             => new external_value(PARAM_TEXT, 'Course name', VALUE_OPTIONAL),
            'authorid'               => new external_value(PARAM_INT, 'Submitter user ID'),
            'authorfullname'         => new external_value(PARAM_TEXT, 'Submitter name'),
            'authorprofileimageurl'  => new external_value(PARAM_URL, 'Submitter image', VALUE_OPTIONAL),
            'reviewerid'             => new external_value(PARAM_INT, 'Reviewer user ID', VALUE_OPTIONAL),
            'reviewerfullname'       => new external_value(PARAM_TEXT, 'Reviewer name', VALUE_OPTIONAL),
            'grade'                  => new external_value(PARAM_FLOAT, 'Grade given', VALUE_OPTIONAL),
            'maxgrade'               => new external_value(PARAM_FLOAT, 'Max possible grade'),
            'feedbackauthor'         => new external_value(PARAM_RAW, 'Feedback text', VALUE_OPTIONAL),
            'status'                 => new external_value(PARAM_TEXT, 'pending|inprogress|completed|overdue'),
            'timesubmitted'          => new external_value(PARAM_INT, 'Submission timestamp', VALUE_OPTIONAL),
            'timereviewed'           => new external_value(PARAM_INT, 'Review timestamp', VALUE_OPTIONAL),
            'content'                => new external_value(PARAM_RAW, 'Submission content', VALUE_OPTIONAL),
            'attachments'            => new external_multiple_structure(
                new external_value(PARAM_URL, 'Attachment URL'), 'Attachments', VALUE_OPTIONAL
            ),
        ]);
    }

    public static function format_review(\stdClass $r, string $defaultStatus = 'pending'): array {
        global $DB;

        $author = $DB->get_record('user', ['id' => $r->authorid], 'id, firstname, lastname');
        $reviewer = !empty($r->reviewerid) ?
            $DB->get_record('user', ['id' => $r->reviewerid], 'id, firstname, lastname') : null;
        $course = $DB->get_record('course', ['id' => $r->courseid], 'id, fullname');

        $status = $defaultStatus;
        if (!empty($r->grade) && (float)$r->grade >= 0) {
            $status = 'completed';
        }

        return [
            'id'                    => (int)$r->assessmentid,
            'assessmentid'          => (int)$r->assessmentid,
            'workshopid'            => (int)$r->wid,
            'workshopname'          => $r->workshopname ?? '',
            'courseid'              => (int)$r->courseid,
            'coursename'            => $course ? $course->fullname : '',
            'authorid'              => (int)$r->authorid,
            'authorfullname'        => $author ? trim($author->firstname . ' ' . $author->lastname) : '',
            'authorprofileimageurl' => '',
            'reviewerid'            => (int)($r->reviewerid ?? 0),
            'reviewerfullname'      => $reviewer ? trim($reviewer->firstname . ' ' . $reviewer->lastname) : '',
            'grade'                 => $r->grade !== null ? (float)$r->grade : null,
            'maxgrade'              => (float)($r->maxgrade ?? 100),
            'feedbackauthor'        => $r->feedbackauthor ?? '',
            'status'                => $status,
            'timesubmitted'         => (int)($r->timesubmitted ?? 0),
            'timereviewed'          => (int)($r->timereviewed ?? 0),
            'content'               => $r->content ?? '',
            'attachments'           => [],
        ];
    }
}
