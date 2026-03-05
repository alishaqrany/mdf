import 'package:equatable/equatable.dart';

/// An entry in the content protection audit log.
class ProtectionLogEntry extends Equatable {
  final int id;
  final int userId;
  final String userFullName;
  final String action;
  final String details;
  final String deviceName;
  final String platform;
  final String ipAddress;
  final int timestamp;

  const ProtectionLogEntry({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.action,
    this.details = '',
    this.deviceName = '',
    this.platform = '',
    this.ipAddress = '',
    required this.timestamp,
  });

  String get timestampFormatted {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  factory ProtectionLogEntry.fromJson(Map<String, dynamic> json) {
    return ProtectionLogEntry(
      id: json['id'] as int? ?? 0,
      userId: json['userid'] as int? ?? 0,
      userFullName: json['user_fullname'] as String? ?? '',
      action: json['action'] as String? ?? '',
      details: json['details'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      ipAddress: json['ip_address'] as String? ?? '',
      timestamp: json['timecreated'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, userId, action, timestamp];
}
