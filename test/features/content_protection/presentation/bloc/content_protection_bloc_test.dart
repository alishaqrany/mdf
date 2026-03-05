import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/features/content_protection/data/datasources/content_protection_remote_datasource.dart';
import 'package:mdf_app/features/content_protection/domain/entities/protection_settings.dart';
import 'package:mdf_app/features/content_protection/domain/entities/user_device.dart';
import 'package:mdf_app/features/content_protection/presentation/bloc/content_protection_bloc.dart';

class MockContentProtectionDataSource extends Mock
    implements ContentProtectionRemoteDataSource {}

void main() {
  late MockContentProtectionDataSource mockDataSource;
  late ContentProtectionBloc bloc;

  const tSettings = ProtectionSettings(
    enabled: true,
    preventScreenCapture: true,
    preventScreenRecording: true,
    watermarkEnabled: false,
    defaultMaxDevices: 3,
    protectedCourseIds: [],
    protectedContentTypes: [],
  );

  const tDevice = UserDevice(
    id: 1,
    userId: 10,
    deviceId: 'abc123',
    deviceName: 'Pixel 6',
    platform: 'android',
    osVersion: '14',
    appVersion: '1.0.0',
    lastActive: 1704067200,
    registeredAt: 1704067200,
    isCurrentDevice: false,
  );

  final tLogJson = {
    'id': 1,
    'userid': 10,
    'user_fullname': 'John Doe',
    'action': 'device_registered',
    'details': 'Registered device Pixel 6',
    'device_name': 'Pixel 6',
    'platform': 'android',
    'ip_address': '192.168.1.1',
    'timecreated': 1704067200,
  };

  setUp(() {
    mockDataSource = MockContentProtectionDataSource();
    bloc = ContentProtectionBloc(dataSource: mockDataSource);
  });

  tearDown(() => bloc.close());

  test('initial state is ContentProtectionInitial', () {
    expect(bloc.state, isA<ContentProtectionInitial>());
  });

  // ─── LoadProtectionSettings ─────────────────────────────────────────

  group('LoadProtectionSettings', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [Loading, SettingsLoaded] on success',
      build: () {
        when(
          () => mockDataSource.getProtectionSettings(),
        ).thenAnswer((_) async => tSettings);
        return bloc;
      },
      act: (b) => b.add(LoadProtectionSettings()),
      expect: () => [
        isA<ContentProtectionLoading>(),
        isA<ProtectionSettingsLoaded>().having(
          (s) => s.settings.enabled,
          'enabled',
          true,
        ),
      ],
    );

    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [Loading, SettingsLoaded(defaults)] on failure (graceful fallback)',
      build: () {
        when(
          () => mockDataSource.getProtectionSettings(),
        ).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(LoadProtectionSettings()),
      expect: () => [
        isA<ContentProtectionLoading>(),
        isA<ProtectionSettingsLoaded>().having(
          (s) => s.settings.enabled,
          'enabled',
          false,
        ),
      ],
    );
  });

  // ─── SaveProtectionSettings ─────────────────────────────────────────

  group('SaveProtectionSettings', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [Loading, Saved, Loading, SettingsLoaded] on success (auto-reloads)',
      build: () {
        when(
          () => mockDataSource.saveProtectionSettings(tSettings),
        ).thenAnswer((_) async {});
        when(
          () => mockDataSource.getProtectionSettings(),
        ).thenAnswer((_) async => tSettings);
        return bloc;
      },
      act: (b) => b.add(SaveProtectionSettings(settings: tSettings)),
      expect: () => [
        isA<ContentProtectionLoading>(),
        isA<ProtectionSettingsSaved>(),
        isA<ContentProtectionLoading>(),
        isA<ProtectionSettingsLoaded>(),
      ],
    );

    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockDataSource.saveProtectionSettings(tSettings),
        ).thenThrow(Exception('Save failed'));
        return bloc;
      },
      act: (b) => b.add(SaveProtectionSettings(settings: tSettings)),
      expect: () => [
        isA<ContentProtectionLoading>(),
        isA<ContentProtectionError>(),
      ],
    );
  });

  // ─── LoadUserDevices ────────────────────────────────────────────────

  group('LoadUserDevices', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [Loading, DevicesLoaded] on success',
      build: () {
        when(
          () => mockDataSource.getUserDevices(10),
        ).thenAnswer((_) async => [tDevice]);
        when(
          () => mockDataSource.getUserDeviceLimit(10),
        ).thenAnswer((_) async => 3);
        return bloc;
      },
      act: (b) => b.add(const LoadUserDevices(userId: 10)),
      expect: () => [
        isA<ContentProtectionLoading>(),
        isA<UserDevicesLoaded>()
            .having((s) => s.devices.length, 'devices count', 1)
            .having((s) => s.maxDevices, 'maxDevices', 3),
      ],
    );

    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockDataSource.getUserDevices(10),
        ).thenThrow(Exception('Failed'));
        return bloc;
      },
      act: (b) => b.add(const LoadUserDevices(userId: 10)),
      expect: () => [
        isA<ContentProtectionLoading>(),
        isA<ContentProtectionError>(),
      ],
    );
  });

  // ─── RevokeDevice ──────────────────────────────────────────────────

  group('RevokeDevice', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [DeviceRevoked, Loading, DevicesLoaded] - auto refreshes',
      build: () {
        when(() => mockDataSource.revokeDevice(1)).thenAnswer((_) async {});
        when(
          () => mockDataSource.getUserDevices(10),
        ).thenAnswer((_) async => []);
        when(
          () => mockDataSource.getUserDeviceLimit(10),
        ).thenAnswer((_) async => 3);
        return bloc;
      },
      act: (b) => b.add(const RevokeDevice(deviceRecordId: 1, userId: 10)),
      expect: () => [
        isA<DeviceRevoked>(),
        isA<ContentProtectionLoading>(),
        isA<UserDevicesLoaded>().having(
          (s) => s.devices.length,
          'devices count',
          0,
        ),
      ],
    );
  });

  // ─── RevokeAllDevices ──────────────────────────────────────────────

  group('RevokeAllDevices', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [AllDevicesRevoked, Loading, DevicesLoaded] - auto refreshes',
      build: () {
        when(
          () => mockDataSource.revokeAllDevices(10),
        ).thenAnswer((_) async {});
        when(
          () => mockDataSource.getUserDevices(10),
        ).thenAnswer((_) async => []);
        when(
          () => mockDataSource.getUserDeviceLimit(10),
        ).thenAnswer((_) async => 3);
        return bloc;
      },
      act: (b) => b.add(const RevokeAllDevices(userId: 10)),
      expect: () => [
        isA<AllDevicesRevoked>(),
        isA<ContentProtectionLoading>(),
        isA<UserDevicesLoaded>(),
      ],
    );
  });

  // ─── SetUserDeviceLimit ────────────────────────────────────────────

  group('SetUserDeviceLimit', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [DeviceLimitUpdated] on success',
      build: () {
        when(
          () => mockDataSource.setUserDeviceLimit(10, 5),
        ).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(const SetUserDeviceLimit(userId: 10, maxDevices: 5)),
      expect: () => [
        isA<DeviceLimitUpdated>().having((s) => s.maxDevices, 'maxDevices', 5),
      ],
    );
  });

  // ─── LoadUserDeviceLimit ───────────────────────────────────────────

  group('LoadUserDeviceLimit', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [DeviceLimitLoaded] on success',
      build: () {
        when(
          () => mockDataSource.getUserDeviceLimit(10),
        ).thenAnswer((_) async => 5);
        return bloc;
      },
      act: (b) => b.add(const LoadUserDeviceLimit(userId: 10)),
      expect: () => [
        isA<DeviceLimitLoaded>()
            .having((s) => s.maxDevices, 'maxDevices', 5)
            .having((s) => s.userId, 'userId', 10),
      ],
    );
  });

  // ─── LoadProtectionLog ─────────────────────────────────────────────

  group('LoadProtectionLog', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [Loading, LogLoaded] on success',
      build: () {
        when(
          () => mockDataSource.getProtectionLog(
            page: 0,
            perPage: 50,
            action: null,
            userId: null,
          ),
        ).thenAnswer(
          (_) async => {
            'logs': [tLogJson],
            'total': 1,
          },
        );
        return bloc;
      },
      act: (b) => b.add(const LoadProtectionLog()),
      expect: () => [
        isA<ContentProtectionLoading>(),
        isA<ProtectionLogLoaded>()
            .having((s) => s.total, 'total', 1)
            .having((s) => s.logs.length, 'logs count', 1),
      ],
    );

    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockDataSource.getProtectionLog(
            page: 0,
            perPage: 50,
            action: null,
            userId: null,
          ),
        ).thenThrow(Exception('Failed'));
        return bloc;
      },
      act: (b) => b.add(const LoadProtectionLog()),
      expect: () => [
        isA<ContentProtectionLoading>(),
        isA<ContentProtectionError>(),
      ],
    );
  });

  // ─── RegisterCurrentDevice ─────────────────────────────────────────

  group('RegisterCurrentDevice', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [DeviceRegistered] when allowed',
      build: () {
        when(
          () => mockDataSource.registerDevice(
            deviceId: 'abc123',
            deviceName: 'Pixel 6',
            platform: 'android',
            osVersion: '14',
            appVersion: '1.0.0',
          ),
        ).thenAnswer((_) async => {'allowed': true, 'is_new': true});
        return bloc;
      },
      act: (b) => b.add(
        const RegisterCurrentDevice(
          deviceId: 'abc123',
          deviceName: 'Pixel 6',
          platform: 'android',
          osVersion: '14',
          appVersion: '1.0.0',
        ),
      ),
      expect: () => [isA<DeviceRegistered>()],
    );

    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [DeviceAccessDenied] when limit reached',
      build: () {
        when(
          () => mockDataSource.registerDevice(
            deviceId: 'abc123',
            deviceName: 'Pixel 6',
            platform: 'android',
            osVersion: '14',
            appVersion: '1.0.0',
          ),
        ).thenAnswer(
          (_) async => {'allowed': false, 'message': 'Device limit reached'},
        );
        return bloc;
      },
      act: (b) => b.add(
        const RegisterCurrentDevice(
          deviceId: 'abc123',
          deviceName: 'Pixel 6',
          platform: 'android',
          osVersion: '14',
          appVersion: '1.0.0',
        ),
      ),
      expect: () => [isA<DeviceAccessDenied>()],
    );
  });

  // ─── ValidateDeviceAccess ──────────────────────────────────────────

  group('ValidateDeviceAccess', () {
    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [DeviceAccessGranted] when allowed',
      build: () {
        when(() => mockDataSource.validateDeviceAccess('abc123')).thenAnswer(
          (_) async => {'allowed': true, 'reason': 'device_registered'},
        );
        return bloc;
      },
      act: (b) => b.add(const ValidateDeviceAccess(deviceId: 'abc123')),
      expect: () => [isA<DeviceAccessGranted>()],
    );

    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [DeviceAccessDenied] when not allowed',
      build: () {
        when(() => mockDataSource.validateDeviceAccess('abc123')).thenAnswer(
          (_) async => {'allowed': false, 'reason': 'device_limit_reached'},
        );
        return bloc;
      },
      act: (b) => b.add(const ValidateDeviceAccess(deviceId: 'abc123')),
      expect: () => [isA<DeviceAccessDenied>()],
    );

    blocTest<ContentProtectionBloc, ContentProtectionState>(
      'emits [DeviceAccessGranted] on error (fail-open)',
      build: () {
        when(
          () => mockDataSource.validateDeviceAccess('abc123'),
        ).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(const ValidateDeviceAccess(deviceId: 'abc123')),
      expect: () => [isA<DeviceAccessGranted>()],
    );
  });
}
