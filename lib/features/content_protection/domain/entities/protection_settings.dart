import 'package:equatable/equatable.dart';

/// Global content protection settings managed by admin.
class ProtectionSettings extends Equatable {
  final bool enabled;
  final bool preventScreenCapture;
  final bool preventScreenRecording;
  final bool watermarkEnabled;
  final int defaultMaxDevices;
  final List<int> protectedCourseIds;
  final List<String> protectedContentTypes;

  const ProtectionSettings({
    this.enabled = false,
    this.preventScreenCapture = true,
    this.preventScreenRecording = true,
    this.watermarkEnabled = false,
    this.defaultMaxDevices = 2,
    this.protectedCourseIds = const [],
    this.protectedContentTypes = const [],
  });

  bool get isAllCourses => protectedCourseIds.isEmpty;
  bool get isAllContentTypes => protectedContentTypes.isEmpty;

  bool isCourseProtected(int courseId) =>
      enabled && (isAllCourses || protectedCourseIds.contains(courseId));

  bool isContentTypeProtected(String type) =>
      enabled &&
      (isAllContentTypes || protectedContentTypes.contains(type));

  ProtectionSettings copyWith({
    bool? enabled,
    bool? preventScreenCapture,
    bool? preventScreenRecording,
    bool? watermarkEnabled,
    int? defaultMaxDevices,
    List<int>? protectedCourseIds,
    List<String>? protectedContentTypes,
  }) {
    return ProtectionSettings(
      enabled: enabled ?? this.enabled,
      preventScreenCapture: preventScreenCapture ?? this.preventScreenCapture,
      preventScreenRecording:
          preventScreenRecording ?? this.preventScreenRecording,
      watermarkEnabled: watermarkEnabled ?? this.watermarkEnabled,
      defaultMaxDevices: defaultMaxDevices ?? this.defaultMaxDevices,
      protectedCourseIds: protectedCourseIds ?? this.protectedCourseIds,
      protectedContentTypes:
          protectedContentTypes ?? this.protectedContentTypes,
    );
  }

  factory ProtectionSettings.fromJson(Map<String, dynamic> json) {
    // Parse protected course IDs – might be a comma-separated string or a List
    List<int> parseCourseIds(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e is int ? e : int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList();
      }
      if (raw is String && raw.trim().isNotEmpty) {
        return raw
            .split(',')
            .map((e) => int.tryParse(e.trim()) ?? 0)
            .where((e) => e > 0)
            .toList();
      }
      return [];
    }

    // Parse protected content types – might be a comma-separated string or a List
    List<String> parseContentTypes(dynamic raw) {
      if (raw is List) return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    return ProtectionSettings(
      enabled: json['enabled'] == true || json['enabled'] == 1 || json['enabled'] == '1',
      preventScreenCapture: json['prevent_screen_capture'] == true ||
          json['prevent_screen_capture'] == 1 || json['prevent_screen_capture'] == '1',
      preventScreenRecording: json['prevent_screen_recording'] == true ||
          json['prevent_screen_recording'] == 1 || json['prevent_screen_recording'] == '1',
      watermarkEnabled:
          json['watermark_enabled'] == true || json['watermark_enabled'] == 1 || json['watermark_enabled'] == '1',
      defaultMaxDevices: json['default_max_devices'] is int
          ? json['default_max_devices'] as int
          : int.tryParse('${json['default_max_devices']}') ?? 2,
      protectedCourseIds: parseCourseIds(json['protected_course_ids']),
      protectedContentTypes: parseContentTypes(json['protected_content_types']),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled ? 1 : 0,
        'prevent_screen_capture': preventScreenCapture ? 1 : 0,
        'prevent_screen_recording': preventScreenRecording ? 1 : 0,
        'watermark_enabled': watermarkEnabled ? 1 : 0,
        'default_max_devices': defaultMaxDevices,
        'protected_course_ids': protectedCourseIds,
        'protected_content_types': protectedContentTypes,
      };

  @override
  List<Object?> get props => [
        enabled,
        preventScreenCapture,
        preventScreenRecording,
        watermarkEnabled,
        defaultMaxDevices,
        protectedCourseIds,
        protectedContentTypes,
      ];
}
