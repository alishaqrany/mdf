import 'exceptions.dart';
import 'failures.dart';

/// Centralized MDF error handler for converting exceptions to user-friendly failures.
///
/// Used by all repositories and blocs that call MDF API or core Moodle functions
/// through the mdf_mobile service.
class MdfErrorHandler {
  MdfErrorHandler._();

  /// Standard access denied message when the token doesn't have access
  /// to MDF functions (e.g., token is from moodle_mobile_app fallback).
  static const String _accessDeniedAr =
      'تعذر الوصول. التوكن الحالي لا يملك صلاحية استخدام خدمة mdf_mobile.\n'
      'اذهب إلى الملف الشخصي → إعادة مصادقة الخدمة لتحديث التوكن.\n'
      'إذا استمرت المشكلة، تأكد من:\n'
      '• تثبيت إضافة MDF (local_mdf_api) على سيرفر Moodle\n'
      '• تشغيل ترقية قاعدة البيانات (Site Admin → Notifications)\n'
      '• تنظيف الكاش (Purge Caches)';

  static const String _accessDeniedEn =
      'Access denied. Current token does not have mdf_mobile service access.\n'
      'Go to Profile → Re-authenticate Service to refresh your token.\n'
      'If the problem persists, ensure:\n'
      '• MDF plugin (local_mdf_api) is installed on the Moodle server\n'
      '• Database upgrade has run (Site Admin → Notifications)\n'
      '• Caches are purged (Purge Caches)';

  static const String accessDeniedMessage =
      '$_accessDeniedAr\n\n$_accessDeniedEn';

  /// Convert any exception from an MDF API call to a [Failure].
  /// Handles [MoodleException], [ServerException], [AuthException],
  /// [NetworkException] and generic errors with clear messages.
  static Failure handleException(dynamic e, {String featureName = ''}) {
    if (e is NetworkException) {
      return const NetworkFailure();
    }

    if (e is AuthException) {
      return AuthFailure(message: e.message);
    }

    final msg = e.toString();

    // MoodleException from ErrorInterceptor → accessexception
    if (e is MoodleException) {
      if (e.errorCode == 'accessexception') {
        // Instead of giving a fatal token error, give a softer message that the module/feature
        // is disabled or restricted.
        return ServerFailure(
          message:
              'لا تملك الصلاحية للوصول إلى هذه الميزة (${featureName}). قد تكون مقيدة أو غير مفعلة.\nAccess denied to $featureName.',
          errorCode: 'accessexception',
        );
      }
      if (e.errorCode == 'invalidrecord' ||
          e.errorCode == 'invalidrecordunknown') {
        return ServerFailure(
          message: _featureMessage(featureName, 'table_missing'),
          errorCode: e.errorCode,
        );
      }
      return ServerFailure(message: e.message, errorCode: e.errorCode);
    }

    if (e is ServerException) {
      if (e.errorCode == 'accessexception') {
        return ServerFailure(
          message:
              'لا تملك الصلاحية للوصول إلى هذه الميزة (${featureName}). قد تكون مقيدة أو غير مفعلة.\nAccess denied to $featureName.',
          errorCode: 'accessexception',
        );
      }
      return ServerFailure(message: e.message, errorCode: e.errorCode);
    }

    // Fallback: check string patterns for wrapped exceptions
    if (msg.contains('accessexception')) {
      return ServerFailure(
        message:
            'لا تملك الصلاحية للوصول إلى هذه الميزة (${featureName}). قد تكون مقيدة أو غير مفعلة.\nAccess denied to $featureName.',
        errorCode: 'accessexception',
      );
    }

    if (msg.contains('invalidrecordunknown') ||
        msg.contains('invalidrecord') ||
        msg.contains('dml_missing_record_exception')) {
      return ServerFailure(
        message: _featureMessage(featureName, 'table_missing'),
      );
    }

    return ServerFailure(message: msg);
  }

  /// Generate a feature-specific error message.
  static String _featureMessage(String featureName, String type) {
    switch (type) {
      case 'table_missing':
        if (featureName.isNotEmpty) {
          return 'ميزة $featureName تتطلب ترقية إضافة MDF على سيرفر Moodle.\n'
              'اذهب إلى Site Admin → Notifications لتشغيل الترقية ثم Purge Caches.\n\n'
              '$featureName requires upgrading the MDF plugin.\n'
              'Go to Site Admin → Notifications to run the upgrade, then Purge Caches.';
        }
        return 'تعذر الوصول لجدول قاعدة البيانات. شغّل ترقية الإضافة من Site Admin → Notifications.\n\n'
            'Database table missing. Run plugin upgrade from Site Admin → Notifications.';
      default:
        return 'حدث خطأ غير متوقع.\nAn unexpected error occurred.';
    }
  }
}
