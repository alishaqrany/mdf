import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/protection_log_entry.dart';
import '../bloc/content_protection_bloc.dart';

/// Admin page showing the content protection audit log.
class ProtectionLogPage extends StatefulWidget {
  const ProtectionLogPage({super.key});

  @override
  State<ProtectionLogPage> createState() => _ProtectionLogPageState();
}

class _ProtectionLogPageState extends State<ProtectionLogPage> {
  String? _selectedAction;
  final _userIdController = TextEditingController();
  int _currentPage = 0;

  static const _actionFilters = [
    'device_registered',
    'device_revoked',
    'device_limit_exceeded',
    'screen_capture_blocked',
    'settings_changed',
    'access_denied',
    'login',
    'logout',
  ];

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocProvider(
      create: (_) =>
          sl<ContentProtectionBloc>()..add(const LoadProtectionLog()),
      child: Scaffold(
        appBar: AppBar(title: Text('content_protection.protection_log'.tr())),
        body: Column(
          children: [
            // ─── Filters ───
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedAction,
                      decoration: InputDecoration(
                        labelText: 'content_protection.filter_action'.tr(),
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('content_protection.all_actions'.tr()),
                        ),
                        ..._actionFilters.map(
                          (a) => DropdownMenuItem(value: a, child: Text(a)),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedAction = v;
                          _currentPage = 0;
                        });
                        _loadLog(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _userIdController,
                      decoration: InputDecoration(
                        labelText: 'content_protection.user_id_filter'.tr(),
                        isDense: true,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) {
                        _currentPage = 0;
                        _loadLog(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      _currentPage = 0;
                      _loadLog(context);
                    },
                  ),
                ],
              ),
            ),

            // ─── Log List ───
            Expanded(
              child: BlocBuilder<ContentProtectionBloc, ContentProtectionState>(
                builder: (context, state) {
                  if (state is ContentProtectionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ProtectionLogLoaded) {
                    if (state.logs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: cs.outlineVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'content_protection.no_log_entries'.tr(),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: state.logs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) =>
                                _buildLogEntry(state.logs[index], theme, cs),
                          ),
                        ),
                        // ─── Pagination ───
                        if (state.total > 50)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 0
                                      ? () {
                                          setState(() => _currentPage--);
                                          _loadLog(context);
                                        }
                                      : null,
                                ),
                                Text(
                                  'content_protection.page_info'.tr(
                                    args: [
                                      '${_currentPage + 1}',
                                      '${(state.total / 50).ceil()}',
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed:
                                      (_currentPage + 1) * 50 < state.total
                                      ? () {
                                          setState(() => _currentPage++);
                                          _loadLog(context);
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }
                  if (state is ContentProtectionError) {
                    return Center(
                      child: Text(
                        state.message,
                        style: TextStyle(color: cs.error),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadLog(BuildContext context) {
    final userId = int.tryParse(_userIdController.text.trim());
    context.read<ContentProtectionBloc>().add(
      LoadProtectionLog(
        page: _currentPage,
        action: _selectedAction,
        userId: userId,
      ),
    );
  }

  Widget _buildLogEntry(
    ProtectionLogEntry entry,
    ThemeData theme,
    ColorScheme cs,
  ) {
    IconData icon;
    Color iconColor;

    switch (entry.action) {
      case 'device_registered':
        icon = Icons.phone_android;
        iconColor = Colors.green;
        break;
      case 'device_revoked':
        icon = Icons.phonelink_erase;
        iconColor = Colors.orange;
        break;
      case 'device_limit_exceeded':
        icon = Icons.warning;
        iconColor = cs.error;
        break;
      case 'screen_capture_blocked':
        icon = Icons.screenshot;
        iconColor = cs.error;
        break;
      case 'access_denied':
        icon = Icons.block;
        iconColor = cs.error;
        break;
      case 'settings_changed':
        icon = Icons.settings;
        iconColor = cs.primary;
        break;
      case 'login':
        icon = Icons.login;
        iconColor = Colors.green;
        break;
      case 'logout':
        icon = Icons.logout;
        iconColor = cs.outline;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = cs.outline;
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        title: Text(
          entry.action.replaceAll('_', ' ').toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.userFullName} • ${entry.deviceName}',
              style: theme.textTheme.bodySmall,
            ),
            if (entry.details.isNotEmpty)
              Text(
                entry.details,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              entry.timestampFormatted,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            if (entry.ipAddress.isNotEmpty)
              Text(
                entry.ipAddress,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.outline,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        isThreeLine: entry.details.isNotEmpty,
      ),
    );
  }
}
