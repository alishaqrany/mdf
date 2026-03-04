<?php
namespace local_mdf_api\external;

defined('MOODLE_INTERNAL') || die();

require_once($CFG->libdir . '/externallib.php');

use core_external\external_api;
use core_external\external_function_parameters;
use core_external\external_single_structure;
use core_external\external_value;

/**
 * Proxy a chat completion request to the configured AI provider.
 * This keeps API keys server-side and enforces usage limits.
 */
class proxy_ai_request extends external_api {

    private const PROVIDER_URLS = [
        'gemini'     => 'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent',
        'mistral'    => 'https://api.mistral.ai/v1/chat/completions',
        'cohere'     => 'https://api.cohere.ai/v2/chat',
        'openrouter' => 'https://openrouter.ai/api/v1/chat/completions',
        'groq'       => 'https://api.groq.com/openai/v1/chat/completions',
    ];

    private const DEFAULT_MODELS = [
        'gemini'     => 'gemini-2.0-flash',
        'mistral'    => 'mistral-small-latest',
        'cohere'     => 'command-r-plus',
        'openrouter' => 'meta-llama/llama-3.1-8b-instruct:free',
        'groq'       => 'llama-3.1-8b-instant',
    ];

    public static function execute_parameters(): external_function_parameters {
        return new external_function_parameters([
            'messages' => new external_value(PARAM_RAW, 'JSON array of {role, content} messages'),
            'provider' => new external_value(PARAM_ALPHANUMEXT, 'Provider to use (empty = first enabled)', VALUE_DEFAULT, ''),
        ]);
    }

    public static function execute(string $messages, string $provider = ''): array {
        global $DB, $USER;

        $params = self::validate_parameters(self::execute_parameters(), [
            'messages' => $messages, 'provider' => $provider,
        ]);

        $context = \context_system::instance();
        self::validate_context($context);
        require_capability('local/mdf_api:useai', $context);

        // Check user limits.
        $limit = $DB->get_record('local_mdf_ai_limits', ['userid' => $USER->id]);
        if ($limit) {
            $today      = strtotime('today');
            $monthstart = strtotime('first day of this month midnight');
            $dc = $limit->lastreset >= $today ? (int)$limit->dailycount : 0;
            $mc = $limit->lastreset >= $monthstart ? (int)$limit->monthlycount : 0;
            if ($dc >= (int)$limit->dailylimit || $mc >= (int)$limit->monthlylimit) {
                return [
                    'success'    => false,
                    'content'    => '',
                    'provider'   => '',
                    'model'      => '',
                    'tokensused' => 0,
                    'error'      => 'limit_reached',
                ];
            }
        }

        // Resolve provider config.
        $config = null;
        if (!empty($params['provider'])) {
            $config = $DB->get_record('local_mdf_ai_config', [
                'provider' => $params['provider'], 'enabled' => 1,
            ]);
        }
        if (!$config) {
            // Get first enabled provider.
            $config = $DB->get_record_select('local_mdf_ai_config',
                'enabled = 1', null, '*', IGNORE_MULTIPLE);
        }
        if (!$config || empty($config->apikey)) {
            return [
                'success'    => false,
                'content'    => '',
                'provider'   => '',
                'model'      => '',
                'tokensused' => 0,
                'error'      => 'no_provider',
            ];
        }

        $providerkey = $config->provider;
        $model = !empty($config->model) ? $config->model : (self::DEFAULT_MODELS[$providerkey] ?? '');
        $messagearray = json_decode($params['messages'], true);
        if (!is_array($messagearray)) {
            throw new \invalid_parameter_exception('messages must be valid JSON array');
        }

        // Prepend system prompt if configured.
        if (!empty($config->systemprompt)) {
            array_unshift($messagearray, ['role' => 'system', 'content' => $config->systemprompt]);
        }

        // Build request based on provider.
        try {
            if ($providerkey === 'gemini') {
                $result = self::call_gemini($config, $model, $messagearray);
            } else if ($providerkey === 'cohere') {
                $result = self::call_cohere($config, $model, $messagearray);
            } else {
                // OpenAI-compatible: Mistral, OpenRouter, Groq.
                $result = self::call_openai_compatible($config, $providerkey, $model, $messagearray);
            }
        } catch (\Exception $e) {
            return [
                'success'    => false,
                'content'    => '',
                'provider'   => $providerkey,
                'model'      => $model,
                'tokensused' => 0,
                'error'      => 'api_error: ' . $e->getMessage(),
            ];
        }

        return [
            'success'    => true,
            'content'    => $result['content'],
            'provider'   => $providerkey,
            'model'      => $model,
            'tokensused' => $result['tokens'],
            'error'      => '',
        ];
    }

    private static function call_gemini($config, string $model, array $messages): array {
        $url = str_replace('{model}', $model, self::PROVIDER_URLS['gemini']);
        $url .= '?key=' . $config->apikey;

        // Convert messages to Gemini format.
        $contents = [];
        foreach ($messages as $msg) {
            if ($msg['role'] === 'system') {
                continue; // Gemini handles system prompt differently.
            }
            $contents[] = [
                'role'  => $msg['role'] === 'assistant' ? 'model' : 'user',
                'parts' => [['text' => $msg['content']]],
            ];
        }

        $body = ['contents' => $contents];

        // Add system instruction.
        $systemmsg = '';
        foreach ($messages as $msg) {
            if ($msg['role'] === 'system') {
                $systemmsg .= $msg['content'] . "\n";
            }
        }
        if (!empty($systemmsg)) {
            $body['systemInstruction'] = ['parts' => [['text' => trim($systemmsg)]]];
        }

        if ((int)$config->maxtokens > 0) {
            $body['generationConfig']['maxOutputTokens'] = (int)$config->maxtokens;
        }
        if ((float)$config->temperature >= 0) {
            $body['generationConfig']['temperature'] = (float)$config->temperature;
        }

        $response = self::http_post($url, $body, []);
        $data = json_decode($response, true);

        $content = $data['candidates'][0]['content']['parts'][0]['text'] ?? '';
        $tokens  = ($data['usageMetadata']['totalTokenCount'] ?? 0);

        return ['content' => $content, 'tokens' => (int)$tokens];
    }

    private static function call_cohere($config, string $model, array $messages): array {
        $url = self::PROVIDER_URLS['cohere'];

        // Convert to Cohere v2 format.
        $body = [
            'model'    => $model,
            'messages' => $messages,
        ];

        if ((int)$config->maxtokens > 0) {
            $body['max_tokens'] = (int)$config->maxtokens;
        }
        if ((float)$config->temperature >= 0) {
            $body['temperature'] = (float)$config->temperature;
        }

        $headers = ['Authorization: Bearer ' . $config->apikey];
        $response = self::http_post($url, $body, $headers);
        $data = json_decode($response, true);

        $content = $data['message']['content'][0]['text'] ?? '';
        $tokens  = ($data['usage']['input_tokens'] ?? 0) + ($data['usage']['output_tokens'] ?? 0);

        return ['content' => $content, 'tokens' => (int)$tokens];
    }

    private static function call_openai_compatible($config, string $providerkey, string $model, array $messages): array {
        $url = self::PROVIDER_URLS[$providerkey];
        $body = [
            'model'    => $model,
            'messages' => $messages,
        ];

        if ((int)$config->maxtokens > 0) {
            $body['max_tokens'] = (int)$config->maxtokens;
        }
        if ((float)$config->temperature >= 0) {
            $body['temperature'] = (float)$config->temperature;
        }

        $headers = ['Authorization: Bearer ' . $config->apikey];
        $response = self::http_post($url, $body, $headers);
        $data = json_decode($response, true);

        $content = $data['choices'][0]['message']['content'] ?? '';
        $tokens  = ($data['usage']['total_tokens'] ?? 0);

        return ['content' => $content, 'tokens' => (int)$tokens];
    }

    private static function http_post(string $url, array $body, array $extraheaders): string {
        $ch = curl_init($url);
        $json = json_encode($body);

        $headers = array_merge([
            'Content-Type: application/json',
            'Content-Length: ' . strlen($json),
        ], $extraheaders);

        curl_setopt_array($ch, [
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $json,
            CURLOPT_HTTPHEADER     => $headers,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 60,
            CURLOPT_CONNECTTIMEOUT => 10,
            CURLOPT_SSL_VERIFYPEER => true,
        ]);

        $response = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($response === false) {
            throw new \moodle_exception('curlerror', 'local_mdf_api', '', $error);
        }
        if ($code >= 400) {
            $decoded = json_decode($response, true);
            $msg = $decoded['error']['message'] ?? $decoded['message'] ?? "HTTP $code";
            throw new \moodle_exception('apierror', 'local_mdf_api', '', $msg);
        }

        return $response;
    }

    public static function execute_returns(): external_single_structure {
        return new external_single_structure([
            'success'    => new external_value(PARAM_BOOL, 'Whether the request succeeded'),
            'content'    => new external_value(PARAM_RAW, 'AI response text'),
            'provider'   => new external_value(PARAM_TEXT, 'Provider used'),
            'model'      => new external_value(PARAM_TEXT, 'Model used'),
            'tokensused' => new external_value(PARAM_INT, 'Total tokens used'),
            'error'      => new external_value(PARAM_RAW, 'Error message if failed'),
        ]);
    }
}
