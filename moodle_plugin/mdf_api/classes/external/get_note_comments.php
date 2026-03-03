<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_multiple_structure;
use core_external\external_single_structure;
use core_external\external_value;

class get_note_comments extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'noteid' => new external_value(PARAM_INT, 'Note ID'),
        ]);
    }

    public static function execute(int $noteid): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), ['noteid' => $noteid]);

        $context = \context_system::instance();
        self::validate_context($context);

        $nid = $params['noteid'];
        $DB->get_record('local_mdf_study_notes', ['id' => $nid], 'id', MUST_EXIST);

        $records = $DB->get_records('local_mdf_note_comments', ['noteid' => $nid], 'timecreated ASC');

        $result = [];
        foreach ($records as $c) {
            $author = $DB->get_record('user', ['id' => $c->userid], 'id, firstname, lastname');
            $result[] = [
                'id'                  => (int)$c->id,
                'noteid'              => (int)$c->noteid,
                'userid'              => (int)$c->userid,
                'userfullname'        => $author ? trim($author->firstname . ' ' . $author->lastname) : '',
                'userprofileimageurl' => '',
                'content'             => $c->content ?? '',
                'timecreated'         => (int)$c->timecreated,
            ];
        }

        return $result;
    }

    public static function execute_returns(): external_multiple_structure {
        return new external_multiple_structure(
            self::comment_structure()
        );
    }

    public static function comment_structure(): external_single_structure {
        return new external_single_structure([
            'id'                  => new external_value(PARAM_INT, 'Comment ID'),
            'noteid'              => new external_value(PARAM_INT, 'Note ID'),
            'userid'              => new external_value(PARAM_INT, 'Author ID'),
            'userfullname'        => new external_value(PARAM_TEXT, 'Author name'),
            'userprofileimageurl' => new external_value(PARAM_URL, 'Author image', VALUE_OPTIONAL),
            'content'             => new external_value(PARAM_RAW, 'Comment content'),
            'timecreated'         => new external_value(PARAM_INT, 'Created timestamp'),
        ]);
    }
}
