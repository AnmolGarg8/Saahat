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

  // Low Signal / Battery Saver Colors
  static const Color lowSignalBg = Color(0xFF09090D);
  static const Color lowSignalSurface = Color(0xFF14141D);
  static const Color lowSignalCard = Color(0xFF1B1B26);
  static const Color lowSignalYellow = Color(0xFFFFD600);
  static const Color lowSignalCyan = Color(0xFF00E5FF);
  static const Color lowSignalGreen = Color(0xFF00E676);
  static const Color lowSignalRed = Color(0xFFFF1744);
  static const Color lowSignalBorder = Color(0xFF333348);

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

  static ThemeData get lowSignalDarkTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: lowSignalBg,
      colorScheme: const ColorScheme.dark(
        primary: lowSignalYellow,
        secondary: lowSignalCyan,
        tertiary: lowSignalGreen,
        surface: lowSignalSurface,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        error: lowSignalRed,
      ),
      cardTheme: CardThemeData(
        color: lowSignalCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lowSignalBorder, width: 1.5),
        ),
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lowSignalBg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: lowSignalYellow,
        unselectedItemColor: Color(0xFF9E9E9E),
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
