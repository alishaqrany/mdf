import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../data/datasources/ai_remote_datasource.dart';
import '../../data/models/ai_config_model.dart';
import '../../data/models/ai_usage_model.dart';
import '../bloc/ai_admin_bloc.dart';

/// Admin page for managing AI provider configurations, usage stats & limits.
class AiAdminPage extends StatelessWidget {
  const AiAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AiAdminBloc(dataSource: GetIt.instance<AiRemoteDataSource>())
            ..add(const LoadAiAdminData()),
      child: const _AiAdminView(),
    );
  }
}

class _AiAdminView extends StatelessWidget {
  const _AiAdminView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('ai_admin.title'))),
      body: BlocConsumer<AiAdminBloc, AiAdminState>(
        listener: (context, state) {
          if (state is AiAdminError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AiAdminLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AiAdminLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AiAdminBloc>().add(const LoadAiAdminData());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── Usage Stats Section ───
                  _UsageStatsCard(stats: state.stats),
                  const SizedBox(height: 16),

                  // ─── Default Limits Section ───
                  _DefaultLimitsCard(limits: state.defaultLimits),
                  const SizedBox(height: 16),

                  // ─── Provider Configs ───
                  Text(
                    tr('ai_admin.providers'),
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ..._buildProviderCards(context, state.configs),

                  // ─── Chat History Button ───
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<AiAdminBloc>().add(
                        const LoadAiChatHistory(),
                      );
                      _showChatHistorySheet(context);
                    },
                    icon: const Icon(Icons.history),
                    label: Text(tr('ai_admin.view_history')),
                  ),
                ],
              ),
            );
          }
          if (state is AiAdminError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<AiAdminBloc>().add(
                      const LoadAiAdminData(),
                    ),
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  List<Widget> _buildProviderCards(
    BuildContext context,
    List<AiConfigModel> configs,
  ) {
    // Ensure all 5 providers are shown, even if not yet configured
    final configMap = <String, AiConfigModel>{};
    for (final c in configs) {
      configMap[c.provider] = c;
    }

    return AiConfigModel.allProviders.map((provider) {
      final config =
          configMap[provider] ??
          AiConfigModel(
            provider: provider,
            model: AiConfigModel.defaultModels[provider] ?? '',
          );
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ProviderConfigCard(config: config),
      );
    }).toList();
  }

  void _showChatHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AiAdminBloc>(),
        child: const _ChatHistorySheet(),
      ),
    );
  }
}

// ─── Usage Stats Card ───
class _UsageStatsCard extends StatelessWidget {
  final AiUsageStatsModel stats;
  const _UsageStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('ai_admin.usage_stats'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: tr('ai_admin.total_messages'),
                    value: stats.totalmessages.toString(),
                    icon: Icons.chat_bubble_outline,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: tr('ai_admin.total_tokens'),
                    value: _formatNumber(stats.totaltokens),
                    icon: Icons.token_outlined,
                  ),
                ),
                Expanded(
                  child: _StatTile(
                    label: tr('ai_admin.unique_users'),
                    value: stats.uniqueusers.toString(),
                    icon: Icons.people_outline,
                  ),
                ),
              ],
            ),
            if (stats.providers.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                tr('ai_admin.per_provider'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ...stats.providers.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AiConfigModel.displayName(p.provider)),
                      Text(
                        '${p.messages} msgs / ${_formatNumber(p.tokens)} tokens',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ─── Stat Tile ───
class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Default Limits Card ───
class _DefaultLimitsCard extends StatelessWidget {
  final AiUserLimitModel limits;
  const _DefaultLimitsCard({required this.limits});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('ai_admin.default_limits'),
                  style: theme.textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditLimitsDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LimitBar(
              label: tr('ai_admin.daily_limit'),
              current: limits.dailycount,
              max: limits.dailylimit,
            ),
            const SizedBox(height: 8),
            _LimitBar(
              label: tr('ai_admin.monthly_limit'),
              current: limits.monthlycount,
              max: limits.monthlylimit,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLimitsDialog(BuildContext context) {
    final dailyCtrl = TextEditingController(text: limits.dailylimit.toString());
    final monthlyCtrl = TextEditingController(
      text: limits.monthlylimit.toString(),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(tr('ai_admin.edit_limits')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dailyCtrl,
              decoration: InputDecoration(
                labelText: tr('ai_admin.daily_limit'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: monthlyCtrl,
              decoration: InputDecoration(
                labelText: tr('ai_admin.monthly_limit'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              final daily = int.tryParse(dailyCtrl.text) ?? 50;
              final monthly = int.tryParse(monthlyCtrl.text) ?? 1000;
              context.read<AiAdminBloc>().add(
                SetAiUserLimits(
                  userid: 0,
                  dailylimit: daily,
                  monthlylimit: monthly,
                ),
              );
              Navigator.pop(dialogCtx);
            },
            child: Text(tr('common.save')),
          ),
        ],
      ),
    );
  }
}

// ─── Limit Progress Bar ───
class _LimitBar extends StatelessWidget {
  final String label;
  final int current;
  final int max;

  const _LimitBar({
    required this.label,
    required this.current,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final color = ratio < 0.7
        ? Colors.green
        : ratio < 0.9
        ? Colors.orange
        : theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text('$current / $max', style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }
}

// ─── Provider Config Card ───
class _ProviderConfigCard extends StatelessWidget {
  final AiConfigModel config;
  const _ProviderConfigCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        leading: Icon(
          config.enabled ? Icons.check_circle : Icons.circle_outlined,
          color: config.enabled ? Colors.green : theme.colorScheme.outline,
        ),
        title: Text(AiConfigModel.displayName(config.provider)),
        subtitle: Text(
          config.enabled
              ? '${tr("ai_admin.model")}: ${config.model}'
              : tr('ai_admin.not_configured'),
          style: theme.textTheme.bodySmall,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _ProviderConfigForm(config: config),
          ),
        ],
      ),
    );
  }
}

// ─── Provider Config Form ───
class _ProviderConfigForm extends StatefulWidget {
  final AiConfigModel config;
  const _ProviderConfigForm({required this.config});

  @override
  State<_ProviderConfigForm> createState() => _ProviderConfigFormState();
}

class _ProviderConfigFormState extends State<_ProviderConfigForm> {
  late final TextEditingController _apikeyCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _promptCtrl;
  late final TextEditingController _maxTokensCtrl;
  late double _temperature;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _apikeyCtrl = TextEditingController(text: widget.config.apikey);
    _modelCtrl = TextEditingController(
      text: widget.config.model.isNotEmpty
          ? widget.config.model
          : AiConfigModel.defaultModels[widget.config.provider] ?? '',
    );
    _promptCtrl = TextEditingController(text: widget.config.systemprompt);
    _maxTokensCtrl = TextEditingController(
      text: widget.config.maxtokens.toString(),
    );
    _temperature = widget.config.temperature;
    _enabled = widget.config.enabled;
  }

  @override
  void dispose() {
    _apikeyCtrl.dispose();
    _modelCtrl.dispose();
    _promptCtrl.dispose();
    _maxTokensCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text(tr('ai_admin.enabled')),
          value: _enabled,
          onChanged: (v) => setState(() => _enabled = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _apikeyCtrl,
          decoration: InputDecoration(
            labelText: tr('ai_admin.api_key'),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.visibility_off),
              onPressed: () {},
            ),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modelCtrl,
          decoration: InputDecoration(
            labelText: tr('ai_admin.model'),
            border: const OutlineInputBorder(),
            helperText:
                '${tr("ai_admin.default")}: ${AiConfigModel.defaultModels[widget.config.provider] ?? ""}',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _promptCtrl,
          decoration: InputDecoration(
            labelText: tr('ai_admin.system_prompt'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _maxTokensCtrl,
          decoration: InputDecoration(
            labelText: tr('ai_admin.max_tokens'),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '${tr("ai_admin.temperature")}: ${_temperature.toStringAsFixed(1)}',
            ),
            Expanded(
              child: Slider(
                min: 0.0,
                max: 2.0,
                divisions: 20,
                value: _temperature,
                onChanged: (v) => setState(() => _temperature = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            context.read<AiAdminBloc>().add(
              SaveAiProviderConfig(
                config: AiConfigModel(
                  provider: widget.config.provider,
                  apikey: _apikeyCtrl.text.trim(),
                  model: _modelCtrl.text.trim(),
                  systemprompt: _promptCtrl.text.trim(),
                  maxtokens: int.tryParse(_maxTokensCtrl.text) ?? 1024,
                  temperature: _temperature,
                  enabled: _enabled,
                ),
              ),
            );
          },
          child: Text(tr('common.save')),
        ),
      ],
    );
  }
}

// ─── Chat History Sheet ───
class _ChatHistorySheet extends StatelessWidget {
  const _ChatHistorySheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return BlocBuilder<AiAdminBloc, AiAdminState>(
          builder: (context, state) {
            List<dynamic> messages = [];
            if (state is AiAdminLoaded && state.chatHistory != null) {
              messages = state.chatHistory!;
            } else if (state is AiAdminChatHistoryLoaded) {
              messages = state.messages;
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    tr('ai_admin.chat_history'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (messages.isEmpty)
                  Expanded(
                    child: Center(child: Text(tr('ai_admin.no_history'))),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Icon(
                              msg.isUser ? Icons.person : Icons.smart_toy,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            msg.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${msg.provider} • ${msg.dateTime.toString().substring(0, 16)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          dense: true,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
