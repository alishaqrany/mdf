import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'white_label_config.dart';

/// Generates [ThemeData] dynamically from a [WhiteLabelConfig].
///
/// This mirrors [AppTheme] but replaces hard-coded AppColors
/// with the tenant's branding colours.
class TenantTheme {
  TenantTheme._();

  /// Build a light theme from the tenant configuration.
  static ThemeData light(WhiteLabelConfig config, {String locale = 'en'}) {
    final primary = config.primaryColor;
    final secondary = config.secondaryColor;
    final surface = config.surfaceColor ?? Colors.white;
    final background = config.backgroundColor ?? const Color(0xFFF5F5FA);

    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primary.withValues(alpha: 0.08),
      secondary: secondary,
      onSecondary: Colors.white,
      error: Colors.red.shade700,
      surface: surface,
      onSurface: const Color(0xFF1A1A2E),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.08),
        elevation: 2,
        height: 65,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
    );
  }

  /// Build a dark theme from the tenant configuration.
  static ThemeData dark(WhiteLabelConfig config, {String locale = 'en'}) {
    final primary = config.primaryColor;
    final secondary = config.secondaryColor;
    const surfaceDark = Color(0xFF1E1E30);
    const backgroundDark = Color(0xFF121220);

    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF2A2A4A),
      secondary: secondary,
      onSecondary: Colors.white,
      error: Colors.red.shade400,
      surface: surfaceDark,
      onSurface: const Color(0xFFE8E8F0),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: const Color(0xFFE8E8F0),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF252540),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: const Color(0xFF2A2A4A),
        elevation: 2,
        height: 65,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
    );
  }
}
