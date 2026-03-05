import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/user_device.dart';
import '../bloc/content_protection_bloc.dart';

/// Page for admins to manage user devices and device limits.
/// Can be navigated with a userId query param to view a specific user,
/// or without to show a user search interface.
class DeviceManagementPage extends StatefulWidget {
  final int? userId;
  const DeviceManagementPage({super.key, this.userId});

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final _searchController = TextEditingController();
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.userId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocProvider(
      create: (_) {
        final bloc = sl<ContentProtectionBloc>();
        if (_selectedUserId != null) {
          bloc.add(LoadUserDevices(userId: _selectedUserId!));
        }
        return bloc;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('content_protection.device_management'.tr()),
        ),
        body: BlocConsumer<ContentProtectionBloc, ContentProtectionState>(
          listener: (context, state) {
            if (state is DeviceRevoked || state is AllDevicesRevoked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('content_protection.device_revoked'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is DeviceLimitUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('content_protection.device_limit_updated'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is ContentProtectionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: cs.error,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // ─── User Search ───
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'content_protection.search_user_id'.tr(),
                      hintText: 'content_protection.enter_user_id'.tr(),
                      prefixIcon: const Icon(Icons.person_search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          final id = int.tryParse(
                            _searchController.text.trim(),
                          );
                          if (id != null && id > 0) {
                            setState(() => _selectedUserId = id);
                            context.read<ContentProtectionBloc>().add(
                              LoadUserDevices(userId: id),
                            );
                          }
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (value) {
                      final id = int.tryParse(value.trim());
                      if (id != null && id > 0) {
                        setState(() => _selectedUserId = id);
                        context.read<ContentProtectionBloc>().add(
                          LoadUserDevices(userId: id),
                        );
                      }
                    },
                  ),
                ),

                // ─── Content ───
                Expanded(
                  child: _selectedUserId == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.devices_other,
                                size: 64,
                                color: cs.outlineVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'content_protection.search_user_prompt'.tr(),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildDeviceList(context, state, theme, cs),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeviceList(
    BuildContext context,
    ContentProtectionState state,
    ThemeData theme,
    ColorScheme cs,
  ) {
    if (state is ContentProtectionLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is UserDevicesLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<ContentProtectionBloc>().add(
            LoadUserDevices(userId: _selectedUserId!),
          );
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // ─── Device Limit Card ───
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.device_hub, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'content_protection.device_limit'.tr(),
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            'content_protection.devices_used'.tr(
                              args: [
                                '${state.devices.length}',
                                '${state.maxDevices}',
                              ],
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: DropdownButtonFormField<int>(
                        value: state.maxDevices.clamp(1, 10),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          ...List.generate(10, (i) => i + 1).map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text('$v')),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            context.read<ContentProtectionBloc>().add(
                              SetUserDeviceLimit(
                                userId: _selectedUserId!,
                                maxDevices: v,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ─── Actions ───
            if (state.devices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'content_protection.registered_devices'.tr(),
                      style: theme.textTheme.titleSmall,
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.delete_sweep, color: cs.error),
                      label: Text(
                        'content_protection.revoke_all'.tr(),
                        style: TextStyle(color: cs.error),
                      ),
                      onPressed: () => _showRevokeAllDialog(context),
                    ),
                  ],
                ),
              ),

            // ─── Device Cards ───
            if (state.devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'content_protection.no_devices'.tr(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...state.devices.map(
                (device) => _buildDeviceCard(context, device, theme, cs),
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDeviceCard(
    BuildContext context,
    UserDevice device,
    ThemeData theme,
    ColorScheme cs,
  ) {
    IconData platformIcon;
    switch (device.platform.toLowerCase()) {
      case 'android':
        platformIcon = Icons.phone_android;
        break;
      case 'ios':
        platformIcon = Icons.phone_iphone;
        break;
      case 'web':
        platformIcon = Icons.language;
        break;
      case 'windows':
        platformIcon = Icons.desktop_windows;
        break;
      case 'macos':
        platformIcon = Icons.laptop_mac;
        break;
      default:
        platformIcon = Icons.devices;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: device.isCurrentDevice ? cs.primary : cs.outlineVariant,
          width: device.isCurrentDevice ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(platformIcon, color: cs.primary),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(device.deviceName, overflow: TextOverflow.ellipsis),
            ),
            if (device.isCurrentDevice)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'content_protection.current_device'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${device.platform} • ${device.osVersion}'),
            Text(
              'content_protection.last_active'.tr(
                args: [device.lastActiveFormatted],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: cs.error),
          tooltip: 'content_protection.revoke_device'.tr(),
          onPressed: () => _showRevokeDialog(context, device),
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showRevokeDialog(BuildContext context, UserDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('content_protection.revoke_device'.tr()),
        content: Text(
          'content_protection.revoke_device_confirm'.tr(
            args: [device.deviceName],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              context.read<ContentProtectionBloc>().add(
                RevokeDevice(
                  deviceRecordId: device.id,
                  userId: _selectedUserId!,
                ),
              );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('content_protection.revoke'.tr()),
          ),
        ],
      ),
    );
  }

  void _showRevokeAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('content_protection.revoke_all'.tr()),
        content: Text('content_protection.revoke_all_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              context.read<ContentProtectionBloc>().add(
                RevokeAllDevices(userId: _selectedUserId!),
              );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('content_protection.revoke_all'.tr()),
          ),
        ],
      ),
    );
  }
}
