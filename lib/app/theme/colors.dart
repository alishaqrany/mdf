import 'package:flutter/material.dart';

/// App color palette — modern educational theme
class AppColors {
  AppColors._();

  // ─── Primary ───
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42E8);
  static const Color primarySurface = Color(0xFFF0EFFF);

  // ─── Secondary ───
  static const Color secondary = Color(0xFF00BFA6);
  static const Color secondaryLight = Color(0xFF5DF2D6);
  static const Color secondaryDark = Color(0xFF008E76);

  // ─── Accent ───
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF9B9B);

  // ─── Background ───
  static const Color backgroundLight = Color(0xFFF8F9FD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surfaceDark = Color(0xFF16213E);
  static const Color cardDark = Color(0xFF1F2940);

  // ─── Text ───
  static const Color textPrimaryLight = Color(0xFF1E1E2D);
  static const Color textSecondaryLight = Color(0xFF6E6E82);
  static const Color textTertiaryLight = Color(0xFF9E9EB8);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFB0B0C8);
  static const Color textTertiaryDark = Color(0xFF6E6E82);

  // ─── Status ───
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ─── Misc ───
  static const Color divider = Color(0xFFE8E8EE);
  static const Color dividerDark = Color(0xFF2A2A4A);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF2A2A4A);
  static const Color shimmerHighlightDark = Color(0xFF3A3A5A);
  static const Color overlay = Color(0x80000000);

  // ─── Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B83FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF00E5C4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Course Category Colors ───
  static const List<Color> categoryColors = [
    Color(0xFF6C63FF),
    Color(0xFF00BFA6),
    Color(0xFFFF6B6B),
    Color(0xFFFFB74D),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFF26C6DA),
    Color(0xFF66BB6A),
  ];
}
