import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App typography using Cairo for Arabic and Poppins for English
class AppTypography {
  AppTypography._();

  // ─── Arabic Font (Cairo) ───
  static TextTheme arabicTextTheme(Color textColor) {
    return GoogleFonts.cairoTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textColor),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textColor),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }

  // ─── English Font (Poppins) ───
  static TextTheme englishTextTheme(Color textColor) {
    return GoogleFonts.poppinsTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textColor),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textColor),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textColor),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textColor),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}
