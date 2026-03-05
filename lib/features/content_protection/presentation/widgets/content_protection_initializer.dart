import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/datasources/content_protection_remote_datasource.dart';
import '../../domain/entities/protection_settings.dart';
import '../../services/device_info_helper.dart';
import '../../services/screen_protection_service.dart';

/// Mixin or standalone widget that initializes content protection
/// after user authentication. Registers the device and enables
/// screen protection based on server settings.
class ContentProtectionInitializer extends StatefulWidget {
  final Widget child;
  const ContentProtectionInitializer({super.key, required this.child});

  @override
  State<ContentProtectionInitializer> createState() =>
      _ContentProtectionInitializerState();
}

class _ContentProtectionInitializerState
    extends State<ContentProtectionInitializer> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && !_initialized) {
          _initialized = true;
          _initProtection(state.user);
        }
        if (state is AuthUnauthenticated) {
          _initialized = false;
          ScreenProtectionService.disable();
        }
      },
      child: widget.child,
    );
  }

  Future<void> _initProtection(User user) async {
    try {
      // Admins are exempt from device limits
      if (user.isAdmin) {
        dev.log(
          '[ContentProtection] Admin user — skipping device registration',
        );
        return;
      }

      final dataSource = sl<ContentProtectionRemoteDataSource>();

      // 1. Collect device info
      final deviceInfo = await DeviceInfoHelper.collectDeviceInfo();

      // 2. Register device (server will check limits)
      final result = await dataSource.registerDevice(
        deviceId: deviceInfo['device_id'] ?? 'unknown',
        deviceName: deviceInfo['device_name'] ?? 'Unknown',
        platform: deviceInfo['platform'] ?? 'unknown',
        osVersion: deviceInfo['os_version'] ?? '',
        appVersion: deviceInfo['app_version'] ?? '',
      );

      dev.log('[ContentProtection] Device registered: $result');

      // 3. Check if access was denied (device limit)
      if (result['allowed'] == false) {
        dev.log(
          '[ContentProtection] Device access DENIED: ${result['message']}',
        );
        // The server rejected this device — we could force logout
        // but for now we'll just log it
      }

      // 4. Load protection settings and apply screen protection
      final settings = await dataSource.getProtectionSettings();
      _applyProtection(settings);
    } catch (e) {
      dev.log('[ContentProtection] Init error: $e');
    }
  }

  void _applyProtection(ProtectionSettings settings) {
    if (settings.enabled &&
        (settings.preventScreenCapture || settings.preventScreenRecording)) {
      ScreenProtectionService.enable();
      dev.log('[ContentProtection] Screen protection ENABLED');
    } else {
      ScreenProtectionService.disable();
      dev.log('[ContentProtection] Screen protection DISABLED');
    }
  }
}
