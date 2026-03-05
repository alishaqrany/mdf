import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/user_device.dart';
import '../bloc/content_protection_bloc.dart';

/// Student view of their own registered devices.
class MyDevicesPage extends StatelessWidget {
  const MyDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;

    return BlocProvider(
      create: (_) =>
          sl<ContentProtectionBloc>()..add(LoadUserDevices(userId: userId)),
      child: Scaffold(
        appBar: AppBar(title: Text('content_protection.my_devices'.tr())),
        body: BlocBuilder<ContentProtectionBloc, ContentProtectionState>(
          builder: (context, state) {
            if (state is ContentProtectionLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is UserDevicesLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ContentProtectionBloc>().add(
                    LoadUserDevices(userId: userId),
                  );
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ─── Info Card ───
                    Card(
                      elevation: 0,
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: cs.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'content_protection.devices_info'.tr(
                                  args: [
                                    '${state.devices.length}',
                                    '${state.maxDevices}',
                                  ],
                                ),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Device List ───
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
                        (device) =>
                            _buildDeviceCard(context, device, theme, cs),
                      ),
                  ],
                ),
              );
            }
            if (state is ContentProtectionError) {
              return Center(
                child: Text(state.message, style: TextStyle(color: cs.error)),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
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
        isThreeLine: true,
      ),
    );
  }
}
