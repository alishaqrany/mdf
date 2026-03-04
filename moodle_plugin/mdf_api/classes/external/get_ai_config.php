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
 * Get all AI provider configurations.
 */
class get_ai_config extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([]);
    }

    public static function execute(): array {
        global $DB;

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:manageai', $context);

        $records = $DB->get_records('local_mdf_ai_config', null, 'provider ASC');
        $configs = [];
        foreach ($records as $rec) {
            $configs[] = [
                'id'           => (int)$rec->id,
                'provider'     => $rec->provider,
                'apikey'       => $rec->apikey,
                'model'        => $rec->model ?? '',
                'systemprompt' => $rec->systemprompt ?? '',
                'maxtokens'    => (int)$rec->maxtokens,
                'temperature'  => (float)$rec->temperature,
                'enabled'      => (int)$rec->enabled,
                'timecreated'  => (int)$rec->timecreated,
                'timemodified' => (int)$rec->timemodified,
            ];
        }

        return ['configs' => $configs];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'configs' => new external_multiple_structure(
                new external_single_structure([
                    'id'           => new external_value(PARAM_INT, 'Config ID'),
                    'provider'     => new external_value(PARAM_ALPHANUMEXT, 'Provider key'),
                    'apikey'       => new external_value(PARAM_RAW, 'API key'),
                    'model'        => new external_value(PARAM_TEXT, 'Model identifier'),
                    'systemprompt' => new external_value(PARAM_RAW, 'System prompt'),
                    'maxtokens'    => new external_value(PARAM_INT, 'Max tokens'),
                    'temperature'  => new external_value(PARAM_FLOAT, 'Temperature'),
                    'enabled'      => new external_value(PARAM_INT, 'Enabled flag'),
                    'timecreated'  => new external_value(PARAM_INT, 'Created timestamp'),
                    'timemodified' => new external_value(PARAM_INT, 'Modified timestamp'),
                ])
            ),
        ]);
    }
}
