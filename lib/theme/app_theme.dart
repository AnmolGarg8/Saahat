import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary & Secondary Brand Colors
  static const Color primaryPurple = Color(0xFF6C2BD9);
  static const Color secondaryMagenta = Color(0xFFFF4D8D);

  // Accent Colors
  static const Color accentGold = Color(0xFFFFC857);
  static const Color accentTeal = Color(0xFF00C2A8);

  // Background & Surface Colors
  static const Color softLavenderBg = Color(0xFFF7F5FC);
  static const Color surfaceWhite = Colors.white;

  // SOS Emergency Color
  static const Color sosCoralRed = Color(0xFFFF385C);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: softLavenderBg,
      colorScheme: ColorScheme.light(
        primary: primaryPurple,
        secondary: secondaryMagenta,
        tertiary: accentTeal,
        surface: surfaceWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: const Color(0xFF1E1E2D),
        displayColor: const Color(0xFF1E1E2D),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: softLavenderBg,
        foregroundColor: const Color(0xFF1E1E2D),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF1E1E2D),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryPurple,
        unselectedItemColor: Color(0xFF94A3B8),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
