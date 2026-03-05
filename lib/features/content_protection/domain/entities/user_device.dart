import 'package:equatable/equatable.dart';

/// Represents a registered device for a user.
class UserDevice extends Equatable {
  final int id;
  final int userId;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String osVersion;
  final String appVersion;
  final int lastActive;
  final int registeredAt;
  final bool isCurrentDevice;

  const UserDevice({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.osVersion = '',
    this.appVersion = '',
    this.lastActive = 0,
    this.registeredAt = 0,
    this.isCurrentDevice = false,
  });

  String get lastActiveFormatted {
    if (lastActive == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(lastActive * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: json['id'] as int? ?? 0,
      userId: json['userid'] as int? ?? 0,
      deviceId: json['device_id'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      osVersion: json['os_version'] as String? ?? '',
      appVersion: json['app_version'] as String? ?? '',
      lastActive: json['last_active'] as int? ?? 0,
      registeredAt: json['registered_at'] as int? ?? 0,
      isCurrentDevice: json['is_current_device'] == true,
    );
  }

  @override
  List<Object?> get props => [id, userId, deviceId];
}
