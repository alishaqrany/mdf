<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

class submit_review extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'reviewid' => new external_value(PARAM_INT, 'Assessment ID'),
            'rating'   => new external_value(PARAM_FLOAT, 'Rating / Grade'),
            'feedback' => new external_value(PARAM_RAW, 'Feedback text'),
        ]);
    }

    public static function execute(int $reviewid, float $rating, string $feedback): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'reviewid' => $reviewid, 'rating' => $rating, 'feedback' => $feedback,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:submitreview', $context);

        $userid = (int)$USER->id;

        $assessment = $DB->get_record('workshop_assessments', ['id' => $params['reviewid']], '*', MUST_EXIST);

        // Check this user is the assigned reviewer.
        if ((int)$assessment->reviewerid !== $userid) {
            throw new \moodle_exception('nopermission', 'local_mdf_api');
        }

        $assessment->grade = $params['rating'];
        $assessment->feedbackauthor = $params['feedback'];
        $assessment->feedbackauthorformat = FORMAT_HTML;
        $assessment->timemodified = time();
        $DB->update_record('workshop_assessments', $assessment);

        // Award gamification points for completing a review.
        \local_mdf_api\gamification_helper::award_points(
            $userid, 15, 'review_complete',
            'Completed a peer review', (int)$assessment->id
        );

        return ['success' => true, 'message' => 'Review submitted'];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Success flag'),
            'message' => new external_value(PARAM_TEXT, 'Status message'),
        ]);
    }
}
