import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

/// Collects device fingerprint information for device registration.
class DeviceInfoHelper {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Returns a unique device identifier, device name, platform, OS version,
  /// and app version.
  static Future<Map<String, String>> collectDeviceInfo() async {
    String deviceId = 'unknown';
    String deviceName = 'Unknown Device';
    String platform = 'unknown';
    String osVersion = '';

    if (kIsWeb) {
      final info = await _deviceInfo.webBrowserInfo;
      deviceId =
          '${info.browserName.name}_${info.platform ?? 'web'}_${info.userAgent?.hashCode ?? 0}';
      deviceName = '${info.browserName.name} on ${info.platform ?? 'Web'}';
      platform = 'web';
      osVersion = info.userAgent ?? '';
    } else if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      deviceId = info.id;
      deviceName = '${info.brand} ${info.model}';
      platform = 'android';
      osVersion =
          'Android ${info.version.release} (SDK ${info.version.sdkInt})';
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      deviceId = info.identifierForVendor ?? info.name;
      deviceName = info.name;
      platform = 'ios';
      osVersion = '${info.systemName} ${info.systemVersion}';
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      deviceId = info.deviceId;
      deviceName = info.computerName;
      platform = 'windows';
      osVersion =
          'Windows ${info.majorVersion}.${info.minorVersion} (Build ${info.buildNumber})';
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      deviceId = info.systemGUID ?? info.computerName;
      deviceName = info.computerName;
      platform = 'macos';
      osVersion =
          'macOS ${info.majorVersion}.${info.minorVersion}.${info.patchVersion}';
    } else if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      deviceId = info.machineId ?? info.name;
      deviceName = info.prettyName;
      platform = 'linux';
      osVersion = info.versionId ?? '';
    }

    String appVersion = '';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {}

    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'os_version': osVersion,
      'app_version': appVersion,
    };
  }
}
