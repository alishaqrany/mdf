<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');
require_once($CFG->dirroot . '/course/lib.php');
require_once($CFG->dirroot . '/mod/page/lib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Return full page activity content by course-module id.
 *
 * @package    local_mdf_api
 * @copyright  2026 MDF Academy
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class get_page_content extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'cmid' => new external_value(PARAM_INT, 'Course module id for the page activity'),
        ]);
    }

    public static function execute(int $cmid): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'cmid' => $cmid,
        ]);

        $cm = get_coursemodule_from_id('page', $params['cmid'], 0, false, MUST_EXIST);
        $course = $DB->get_record('course', ['id' => $cm->course], '*', MUST_EXIST);
        $page = $DB->get_record('page', ['id' => $cm->instance], '*', MUST_EXIST);

        require_login($course, true, $cm);

        $context = \context_module::instance($cm->id);
        self::validate_context($context);

        $content = file_rewrite_pluginfile_urls(
            $page->content ?? '',
            'webservice/pluginfile.php',
            $context->id,
            'mod_page',
            'content',
            0
        );

        $intro = file_rewrite_pluginfile_urls(
            $page->intro ?? '',
            'webservice/pluginfile.php',
            $context->id,
            'mod_page',
            'intro',
            0
        );

        return [
            'cmid' => (int) $cm->id,
            'courseid' => (int) $course->id,
            'pageid' => (int) $page->id,
            'contextid' => (int) $context->id,
            'name' => format_string($page->name, true, ['context' => $context]),
            'content' => $content,
            'intro' => $intro,
            'url' => (new \moodle_url('/mod/page/view.php', ['id' => $cm->id]))->out(false),
        ];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'cmid' => new external_value(PARAM_INT, 'Course module id'),
            'courseid' => new external_value(PARAM_INT, 'Course id'),
            'pageid' => new external_value(PARAM_INT, 'Page instance id'),
            'contextid' => new external_value(PARAM_INT, 'Module context id'),
            'name' => new external_value(PARAM_RAW, 'Page name'),
            'content' => new external_value(PARAM_RAW, 'Page HTML content'),
            'intro' => new external_value(PARAM_RAW, 'Page intro HTML'),
            'url' => new external_value(PARAM_URL, 'Page view URL'),
        ]);
    }
}