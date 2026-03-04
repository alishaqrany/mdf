<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Save AI provider configuration.
 */
class save_ai_config extends external_api {

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'provider'      => new external_value(PARAM_ALPHANUMEXT, 'Provider key: gemini|mistral|cohere|openrouter|groq'),
            'apikey'        => new external_value(PARAM_RAW, 'API key for the provider'),
            'model'         => new external_value(PARAM_TEXT, 'Model identifier', VALUE_DEFAULT, ''),
            'systemprompt'  => new external_value(PARAM_RAW, 'System prompt', VALUE_DEFAULT, ''),
            'maxtokens'     => new external_value(PARAM_INT, 'Max tokens per response', VALUE_DEFAULT, 1024),
            'temperature'   => new external_value(PARAM_FLOAT, 'Temperature 0.0-2.0', VALUE_DEFAULT, 0.7),
            'enabled'       => new external_value(PARAM_INT, 'Enabled (1=yes, 0=no)', VALUE_DEFAULT, 1),
        ]);
    }

    public static function execute(
        string $provider, string $apikey, string $model = '',
        string $systemprompt = '', int $maxtokens = 1024,
        float $temperature = 0.7, int $enabled = 1
    ): array {
        global $DB;

        $params = self::validate_parameters(self::execute_parameters(), [
            'provider' => $provider, 'apikey' => $apikey, 'model' => $model,
            'systemprompt' => $systemprompt, 'maxtokens' => $maxtokens,
            'temperature' => $temperature, 'enabled' => $enabled,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:manageai', $context);

        $now = time();
        $existing = $DB->get_record('local_mdf_ai_config', ['provider' => $params['provider']]);

        $record = new \stdClass();
        $record->provider     = $params['provider'];
        $record->apikey       = $params['apikey'];
        $record->model        = $params['model'];
        $record->systemprompt = $params['systemprompt'];
        $record->maxtokens    = $params['maxtokens'];
        $record->temperature  = $params['temperature'];
        $record->enabled      = $params['enabled'];
        $record->timemodified = $now;

        if ($existing) {
            $record->id = $existing->id;
            $DB->update_record('local_mdf_ai_config', $record);
        } else {
            $record->timecreated = $now;
            $record->id = $DB->insert_record('local_mdf_ai_config', $record);
        }

        return ['success' => true, 'id' => (int)$record->id];
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success' => new external_value(PARAM_BOOL, 'Whether save succeeded'),
            'id'      => new external_value(PARAM_INT, 'Config record ID'),
        ]);
    }
}
