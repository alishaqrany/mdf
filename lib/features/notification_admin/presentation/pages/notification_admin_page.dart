import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../bloc/notification_admin_bloc.dart';
import '../bloc/notification_admin_event.dart';
import '../bloc/notification_admin_state.dart';

/// Admin notification management page with two tabs:
/// 1. Compose & Send  2. History Log
class NotificationAdminPage extends StatelessWidget {
  const NotificationAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationAdminBloc>(),
      child: const _NotificationAdminView(),
    );
  }
}

class _NotificationAdminView extends StatefulWidget {
  const _NotificationAdminView();

  @override
  State<_NotificationAdminView> createState() => _NotificationAdminViewState();
}

class _NotificationAdminViewState extends State<_NotificationAdminView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('notif_admin.title')),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.send),
              text: tr('notif_admin.tab_compose'),
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: tr('notif_admin.tab_history'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ComposeTab(), _HistoryTab()],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Compose Tab
// ────────────────────────────────────────────────────────────

class _ComposeTab extends StatefulWidget {
  const _ComposeTab();

  @override
  State<_ComposeTab> createState() => _ComposeTabState();
}

class _ComposeTabState extends State<_ComposeTab> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  bool _sendFcm = true;

  // Recipient selection
  final Set<int> _selectedUserIds = {};
  List<Map<String, dynamic>> _users = [];
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    // Load initial users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationAdminBloc>().add(const LoadUsers());
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<NotificationAdminBloc, NotificationAdminState>(
      listener: (context, state) {
        if (state is UsersLoaded) {
          setState(() => _users = state.users);
        } else if (state is NotificationSent) {
          final allFailed = state.totalSent == 0 && state.totalFailed > 0;
          final hasFailures = state.totalFailed > 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: allFailed
                  ? AppColors.error
                  : hasFailures
                      ? Colors.orange
                      : AppColors.success,
              duration: Duration(seconds: hasFailures ? 6 : 3),
            ),
          );
          _subjectController.clear();
          _messageController.clear();
          setState(() {
            _selectedUserIds.clear();
            _selectAll = false;
          });
        } else if (state is NotificationAdminError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Subject ───
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: tr('notif_admin.field_subject'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? tr('common.required') : null,
              ),
              const SizedBox(height: 16),

              // ─── Message ───
              TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: tr('notif_admin.field_message'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.message),
                ),
                maxLines: 5,
                validator: (v) =>
                    (v == null || v.isEmpty) ? tr('common.required') : null,
              ),
              const SizedBox(height: 16),

              // ─── FCM toggle ───
              SwitchListTile(
                title: Text(tr('notif_admin.send_fcm')),
                subtitle: Text(tr('notif_admin.send_fcm_desc')),
                value: _sendFcm,
                onChanged: (v) => setState(() => _sendFcm = v),
              ),
              const Divider(),

              // ─── Recipient Selection ───
              Text(
                tr('notif_admin.recipients'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: tr('notif_admin.search_users'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      context.read<NotificationAdminBloc>().add(
                        LoadUsers(search: _searchController.text),
                      );
                    },
                    icon: const Icon(Icons.search),
                  ),
                ),
                onSubmitted: (v) {
                  context.read<NotificationAdminBloc>().add(
                    LoadUsers(search: v),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Select all checkbox
              CheckboxListTile(
                title: Text(tr('notif_admin.select_all')),
                value: _selectAll,
                onChanged: (v) {
                  setState(() {
                    _selectAll = v ?? false;
                    if (_selectAll) {
                      _selectedUserIds.addAll(
                        _users.map((u) => u['id'] as int),
                      );
                    } else {
                      _selectedUserIds.clear();
                    }
                  });
                },
              ),

              // Selected count
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${tr('notif_admin.selected')}: ${_selectedUserIds.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // User list
              BlocBuilder<NotificationAdminBloc, NotificationAdminState>(
                builder: (context, state) {
                  if (state is NotificationAdminLoading && _users.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (_users.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(tr('notif_admin.no_users'))),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final userId = user['id'] as int;
                      final isSelected = _selectedUserIds.contains(userId);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedUserIds.add(userId);
                            } else {
                              _selectedUserIds.remove(userId);
                            }
                            _selectAll =
                                _selectedUserIds.length == _users.length;
                          });
                        },
                        title: Text(user['fullname'] ?? ''),
                        subtitle: Text(user['email'] ?? ''),
                        secondary: CircleAvatar(
                          backgroundImage: user['profileimageurl'] != null
                              ? NetworkImage(user['profileimageurl'])
                              : null,
                          child: user['profileimageurl'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // ─── Send Button ───
              BlocBuilder<NotificationAdminBloc, NotificationAdminState>(
                builder: (context, state) {
                  final isLoading = state is NotificationAdminLoading;
                  return FilledButton.icon(
                    onPressed: (isLoading || _selectedUserIds.isEmpty)
                        ? null
                        : _onSend,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      '${tr('notif_admin.send')} (${_selectedUserIds.length})',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSend() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUserIds.isEmpty) return;

    context.read<NotificationAdminBloc>().add(
      SendNotifications(
        userIds: _selectedUserIds.toList(),
        subject: _subjectController.text,
        message: _messageController.text,
        sendFcm: _sendFcm,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// History Tab
// ────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationAdminBloc>().add(const LoadNotificationLog());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<NotificationAdminBloc, NotificationAdminState>(
      builder: (context, state) {
        if (state is NotificationAdminLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is NotificationLogLoaded) {
          if (state.logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(tr('notif_admin.no_history')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationAdminBloc>().add(
                const LoadNotificationLog(),
              );
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.logs.length,
              itemBuilder: (context, index) {
                final log = state.logs[index];
                final status = log['status'] ?? '';
                final isSuccess = status == 'sent';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSuccess
                          ? AppColors.success
                          : AppColors.error,
                      child: Icon(
                        isSuccess ? Icons.check : Icons.error,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(log['title'] ?? log['subject'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['message'] ?? log['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tr('notif_admin.to')}: ${log['username'] ?? log['userid'] ?? ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: Text(
                      _formatTimestamp(log['timecreated']),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
          );
        }

        if (state is NotificationAdminError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 8),
                Text(state.message),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.read<NotificationAdminBloc>().add(
                    const LoadNotificationLog(),
                  ),
                  child: Text(tr('common.retry')),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    try {
      final seconds = ts is int ? ts : int.parse(ts.toString());
      final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts.toString();
    }
  }
}
