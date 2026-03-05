import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Manages the app's theme mode (light, dark, system).
/// Persists the user's choice via SharedPreferences.
class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeCubit({required SharedPreferences prefs})
    : _prefs = prefs,
      super(_loadSaved(prefs));

  static ThemeMode _loadSaved(SharedPreferences prefs) {
    final saved = prefs.getString(AppConstants.themeKey);
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode explicitly and persist.
  void setTheme(ThemeMode mode) {
    _prefs.setString(AppConstants.themeKey, mode.name);
    emit(mode);
  }

  /// Toggle between light ↔ dark (skips system).
  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setTheme(next);
  }
}
