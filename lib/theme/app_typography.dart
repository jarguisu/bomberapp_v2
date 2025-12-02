import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme get textTheme {
    // Basado en Inter 400 / 600 / 800
    return TextTheme(
      headlineMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        fontSize: 24,
        height: 1.25,
      ),
      headlineSmall: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        height: 1.25,
      ),
      titleMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.3,
      ),
      titleSmall: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.3,
      ),
      bodyLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        height: 1.3,
      ),
      labelMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 1.3,
      ),
    );
  }
}
