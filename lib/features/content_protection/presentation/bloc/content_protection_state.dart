part of 'content_protection_bloc.dart';

abstract class ContentProtectionState extends Equatable {
  const ContentProtectionState();
  @override
  List<Object?> get props => [];
}

class ContentProtectionInitial extends ContentProtectionState {}

class ContentProtectionLoading extends ContentProtectionState {}

class ProtectionSettingsLoaded extends ContentProtectionState {
  final ProtectionSettings settings;
  const ProtectionSettingsLoaded({required this.settings});
  @override
  List<Object?> get props => [settings];
}

class ProtectionSettingsSaved extends ContentProtectionState {}

class UserDevicesLoaded extends ContentProtectionState {
  final List<UserDevice> devices;
  final int userId;
  final int maxDevices;
  const UserDevicesLoaded({
    required this.devices,
    required this.userId,
    required this.maxDevices,
  });
  @override
  List<Object?> get props => [devices, userId, maxDevices];
}

class DeviceRevoked extends ContentProtectionState {}

class AllDevicesRevoked extends ContentProtectionState {}

class DeviceLimitUpdated extends ContentProtectionState {
  final int maxDevices;
  const DeviceLimitUpdated({required this.maxDevices});
  @override
  List<Object?> get props => [maxDevices];
}

class DeviceLimitLoaded extends ContentProtectionState {
  final int userId;
  final int maxDevices;
  const DeviceLimitLoaded({required this.userId, required this.maxDevices});
  @override
  List<Object?> get props => [userId, maxDevices];
}

class ProtectionLogLoaded extends ContentProtectionState {
  final List<ProtectionLogEntry> logs;
  final int total;
  const ProtectionLogLoaded({required this.logs, required this.total});
  @override
  List<Object?> get props => [logs, total];
}

class DeviceRegistered extends ContentProtectionState {}

class DeviceAccessGranted extends ContentProtectionState {}

class DeviceAccessDenied extends ContentProtectionState {
  final String message;
  const DeviceAccessDenied({required this.message});
  @override
  List<Object?> get props => [message];
}

class ContentProtectionError extends ContentProtectionState {
  final String message;
  const ContentProtectionError({required this.message});
  @override
  List<Object?> get props => [message];
}
