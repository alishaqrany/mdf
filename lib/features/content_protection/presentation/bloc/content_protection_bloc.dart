import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/content_protection_remote_datasource.dart';
import '../../domain/entities/protection_settings.dart';
import '../../domain/entities/user_device.dart';
import '../../domain/entities/protection_log_entry.dart';

part 'content_protection_event.dart';
part 'content_protection_state.dart';

class ContentProtectionBloc
    extends Bloc<ContentProtectionEvent, ContentProtectionState> {
  final ContentProtectionRemoteDataSource dataSource;

  ContentProtectionBloc({required this.dataSource})
      : super(ContentProtectionInitial()) {
    on<LoadProtectionSettings>(_onLoadSettings);
    on<SaveProtectionSettings>(_onSaveSettings);
    on<LoadUserDevices>(_onLoadUserDevices);
    on<RevokeDevice>(_onRevokeDevice);
    on<RevokeAllDevices>(_onRevokeAllDevices);
    on<SetUserDeviceLimit>(_onSetDeviceLimit);
    on<LoadUserDeviceLimit>(_onLoadDeviceLimit);
    on<LoadProtectionLog>(_onLoadLog);
    on<RegisterCurrentDevice>(_onRegisterDevice);
    on<ValidateDeviceAccess>(_onValidateAccess);
  }

  Future<void> _onLoadSettings(
    LoadProtectionSettings event,
    Emitter<ContentProtectionState> emit,
  ) async {
    emit(ContentProtectionLoading());
    try {
      final settings = await dataSource.getProtectionSettings();
      emit(ProtectionSettingsLoaded(settings: settings));
    } catch (e) {
      // If the Moodle plugin isn't installed yet, fall back to defaults
      // so the admin can still see/configure the panel.
      emit(const ProtectionSettingsLoaded(settings: ProtectionSettings()));
    }
  }

  Future<void> _onSaveSettings(
    SaveProtectionSettings event,
    Emitter<ContentProtectionState> emit,
  ) async {
    emit(ContentProtectionLoading());
    try {
      await dataSource.saveProtectionSettings(event.settings);
      emit(ProtectionSettingsSaved());
      add(LoadProtectionSettings());
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalidrecordunknown') || msg.contains('dml_missing_record_exception')) {
        // Settings record may not exist yet — try initializing by loading,
        // then retry the save once.
        try {
          await dataSource.getProtectionSettings();
          await dataSource.saveProtectionSettings(event.settings);
          emit(ProtectionSettingsSaved());
          add(LoadProtectionSettings());
          return;
        } catch (retryError) {
          final retryMsg = retryError.toString().toLowerCase();
          if (retryMsg.contains('invalidrecordunknown') || retryMsg.contains('dml_missing_record_exception')) {
            emit(const ContentProtectionError(
              message: 'لم يتم العثور على سجل الإعدادات في قاعدة البيانات. يرجى زيارة صفحة الإشعارات في Moodle لتحديث قاعدة البيانات.\n'
                  'Settings record not found. Visit Moodle Notifications page to update the database.',
            ));
          } else {
            emit(ContentProtectionError(message: retryError.toString()));
          }
          return;
        }
      }
      emit(ContentProtectionError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserDevices(
    LoadUserDevices event,
    Emitter<ContentProtectionState> emit,
  ) async {
    emit(ContentProtectionLoading());
    try {
      final devices = await dataSource.getUserDevices(event.userId);
      final limit = await dataSource.getUserDeviceLimit(event.userId);
      emit(UserDevicesLoaded(
        devices: devices,
        userId: event.userId,
        maxDevices: limit,
      ));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalidrecordunknown') || msg.contains('dml_missing_record_exception')) {
        // No registered devices yet — return empty list
        emit(UserDevicesLoaded(
          devices: const [],
          userId: event.userId,
          maxDevices: 2,
        ));
      } else {
        emit(ContentProtectionError(message: e.toString()));
      }
    }
  }

  Future<void> _onRevokeDevice(
    RevokeDevice event,
    Emitter<ContentProtectionState> emit,
  ) async {
    try {
      await dataSource.revokeDevice(event.deviceRecordId);
      emit(DeviceRevoked());
      add(LoadUserDevices(userId: event.userId));
    } catch (e) {
      emit(ContentProtectionError(message: e.toString()));
    }
  }

  Future<void> _onRevokeAllDevices(
    RevokeAllDevices event,
    Emitter<ContentProtectionState> emit,
  ) async {
    try {
      await dataSource.revokeAllDevices(event.userId);
      emit(AllDevicesRevoked());
      add(LoadUserDevices(userId: event.userId));
    } catch (e) {
      emit(ContentProtectionError(message: e.toString()));
    }
  }

  Future<void> _onSetDeviceLimit(
    SetUserDeviceLimit event,
    Emitter<ContentProtectionState> emit,
  ) async {
    try {
      await dataSource.setUserDeviceLimit(event.userId, event.maxDevices);
      emit(DeviceLimitUpdated(maxDevices: event.maxDevices));
    } catch (e) {
      emit(ContentProtectionError(message: e.toString()));
    }
  }

  Future<void> _onLoadDeviceLimit(
    LoadUserDeviceLimit event,
    Emitter<ContentProtectionState> emit,
  ) async {
    try {
      final limit = await dataSource.getUserDeviceLimit(event.userId);
      emit(DeviceLimitLoaded(userId: event.userId, maxDevices: limit));
    } catch (e) {
      emit(ContentProtectionError(message: e.toString()));
    }
  }

  Future<void> _onLoadLog(
    LoadProtectionLog event,
    Emitter<ContentProtectionState> emit,
  ) async {
    emit(ContentProtectionLoading());
    try {
      final response = await dataSource.getProtectionLog(
        page: event.page,
        perPage: event.perPage,
        action: event.action,
        userId: event.userId,
      );
      final logs = (response['logs'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => ProtectionLogEntry.fromJson(e))
          .toList();
      final total = response['total'] as int? ?? 0;
      emit(ProtectionLogLoaded(logs: logs, total: total));
    } catch (e) {
      emit(ContentProtectionError(message: e.toString()));
    }
  }

  Future<void> _onRegisterDevice(
    RegisterCurrentDevice event,
    Emitter<ContentProtectionState> emit,
  ) async {
    try {
      final result = await dataSource.registerDevice(
        deviceId: event.deviceId,
        deviceName: event.deviceName,
        platform: event.platform,
        osVersion: event.osVersion,
        appVersion: event.appVersion,
      );
      final allowed = result['allowed'] != false;
      if (!allowed) {
        emit(DeviceAccessDenied(
          message: result['message'] as String? ?? 'Device limit reached',
        ));
      } else {
        emit(DeviceRegistered());
      }
    } catch (e) {
      emit(ContentProtectionError(message: e.toString()));
    }
  }

  Future<void> _onValidateAccess(
    ValidateDeviceAccess event,
    Emitter<ContentProtectionState> emit,
  ) async {
    try {
      final result = await dataSource.validateDeviceAccess(event.deviceId);
      final allowed = result['allowed'] != false;
      if (allowed) {
        emit(DeviceAccessGranted());
      } else {
        emit(DeviceAccessDenied(
          message: result['message'] as String? ?? 'Access denied',
        ));
      }
    } catch (e) {
      // On error, allow access to not block user
      emit(DeviceAccessGranted());
    }
  }
}
