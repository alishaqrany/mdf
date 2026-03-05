part of 'content_protection_bloc.dart';

abstract class ContentProtectionEvent extends Equatable {
  const ContentProtectionEvent();
  @override
  List<Object?> get props => [];
}

class LoadProtectionSettings extends ContentProtectionEvent {}

class SaveProtectionSettings extends ContentProtectionEvent {
  final ProtectionSettings settings;
  const SaveProtectionSettings({required this.settings});
  @override
  List<Object?> get props => [settings];
}

class LoadUserDevices extends ContentProtectionEvent {
  final int userId;
  const LoadUserDevices({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class RevokeDevice extends ContentProtectionEvent {
  final int deviceRecordId;
  final int userId;
  const RevokeDevice({required this.deviceRecordId, required this.userId});
  @override
  List<Object?> get props => [deviceRecordId, userId];
}

class RevokeAllDevices extends ContentProtectionEvent {
  final int userId;
  const RevokeAllDevices({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class SetUserDeviceLimit extends ContentProtectionEvent {
  final int userId;
  final int maxDevices;
  const SetUserDeviceLimit({required this.userId, required this.maxDevices});
  @override
  List<Object?> get props => [userId, maxDevices];
}

class LoadUserDeviceLimit extends ContentProtectionEvent {
  final int userId;
  const LoadUserDeviceLimit({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class LoadProtectionLog extends ContentProtectionEvent {
  final int page;
  final int perPage;
  final String? action;
  final int? userId;
  const LoadProtectionLog({
    this.page = 0,
    this.perPage = 50,
    this.action,
    this.userId,
  });
  @override
  List<Object?> get props => [page, perPage, action, userId];
}

class RegisterCurrentDevice extends ContentProtectionEvent {
  final String deviceId;
  final String deviceName;
  final String platform;
  final String osVersion;
  final String appVersion;
  const RegisterCurrentDevice({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.appVersion,
  });
  @override
  List<Object?> get props => [deviceId, deviceName, platform];
}

class ValidateDeviceAccess extends ContentProtectionEvent {
  final String deviceId;
  const ValidateDeviceAccess({required this.deviceId});
  @override
  List<Object?> get props => [deviceId];
}
