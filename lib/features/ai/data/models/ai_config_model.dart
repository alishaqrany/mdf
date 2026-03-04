/// Model for an AI provider configuration.
class AiConfigModel {
  final int? id;
  final String provider;
  final String apikey;
  final String model;
  final String systemprompt;
  final int maxtokens;
  final double temperature;
  final bool enabled;
  final int? timecreated;
  final int? timemodified;

  const AiConfigModel({
    this.id,
    required this.provider,
    this.apikey = '',
    this.model = '',
    this.systemprompt = '',
    this.maxtokens = 1024,
    this.temperature = 0.7,
    this.enabled = false,
    this.timecreated,
    this.timemodified,
  });

  factory AiConfigModel.fromJson(Map<String, dynamic> json) {
    return AiConfigModel(
      id: json['id'] as int?,
      provider: json['provider'] as String? ?? '',
      apikey: json['apikey'] as String? ?? '',
      model: json['model'] as String? ?? '',
      systemprompt: json['systemprompt'] as String? ?? '',
      maxtokens: json['maxtokens'] as int? ?? 1024,
      temperature: (json['temperature'] is num)
          ? (json['temperature'] as num).toDouble()
          : 0.7,
      enabled: json['enabled'] == 1 || json['enabled'] == true,
      timecreated: json['timecreated'] as int?,
      timemodified: json['timemodified'] as int?,
    );
  }

  AiConfigModel copyWith({
    int? id,
    String? provider,
    String? apikey,
    String? model,
    String? systemprompt,
    int? maxtokens,
    double? temperature,
    bool? enabled,
  }) {
    return AiConfigModel(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      apikey: apikey ?? this.apikey,
      model: model ?? this.model,
      systemprompt: systemprompt ?? this.systemprompt,
      maxtokens: maxtokens ?? this.maxtokens,
      temperature: temperature ?? this.temperature,
      enabled: enabled ?? this.enabled,
      timecreated: timecreated,
      timemodified: timemodified,
    );
  }

  /// Default model names per provider.
  static const defaultModels = <String, String>{
    'gemini': 'gemini-2.0-flash',
    'mistral': 'mistral-small-latest',
    'cohere': 'command-r-plus',
    'openrouter': 'meta-llama/llama-3.1-8b-instruct:free',
    'groq': 'llama-3.1-8b-instant',
  };

  /// Display name for a provider.
  static String displayName(String provider) {
    switch (provider) {
      case 'gemini':
        return 'Google Gemini';
      case 'mistral':
        return 'Mistral AI';
      case 'cohere':
        return 'Cohere';
      case 'openrouter':
        return 'OpenRouter';
      case 'groq':
        return 'Groq';
      default:
        return provider;
    }
  }

  /// All supported provider keys.
  static const allProviders = [
    'gemini',
    'mistral',
    'cohere',
    'openrouter',
    'groq',
  ];
}
