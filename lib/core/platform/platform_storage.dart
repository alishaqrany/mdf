import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'platform_info.dart';

/// Platform-adaptive secure storage.
///
/// On mobile/desktop → uses [FlutterSecureStorage] (encrypted).
/// On web → falls back to [SharedPreferences] with an obfuscated key prefix
/// because FlutterSecureStorage web implementation uses localStorage
/// with encryption which can be unreliable across browsers.
class PlatformStorage {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  /// Prefix for web-fallback keys to avoid collision.
  static const _webPrefix = '__mdf_sec_';

  PlatformStorage({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  }) : _secureStorage = secureStorage,
       _prefs = prefs;

  /// Read a value by key.
  Future<String?> read({required String key}) async {
    if (PlatformInfo.isWeb) {
      return _prefs.getString('$_webPrefix$key');
    }
    return _secureStorage.read(key: key);
  }

  /// Write a key–value pair.
  Future<void> write({required String key, required String value}) async {
    if (PlatformInfo.isWeb) {
      await _prefs.setString('$_webPrefix$key', value);
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  /// Delete a value by key.
  Future<void> delete({required String key}) async {
    if (PlatformInfo.isWeb) {
      await _prefs.remove('$_webPrefix$key');
      return;
    }
    await _secureStorage.delete(key: key);
  }

  /// Check if a key exists.
  Future<bool> containsKey({required String key}) async {
    if (PlatformInfo.isWeb) {
      return _prefs.containsKey('$_webPrefix$key');
    }
    return await _secureStorage.containsKey(key: key);
  }

  /// Delete all secure keys.
  Future<void> deleteAll() async {
    if (PlatformInfo.isWeb) {
      final keys = _prefs.getKeys().where((k) => k.startsWith(_webPrefix));
      for (final k in keys) {
        await _prefs.remove(k);
      }
      return;
    }
    await _secureStorage.deleteAll();
  }
}
