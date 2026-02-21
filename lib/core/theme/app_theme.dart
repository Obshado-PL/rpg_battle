import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.dark,
        surface: const Color(0xFF1A1A2E),
        primary: const Color(0xFF6C63FF),
        secondary: const Color(0xFFE94560),
        tertiary: const Color(0xFF0F3460),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F0F23),
      textTheme: GoogleFonts.pressStart2pTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(fontSize: 20, color: Colors.white),
          headlineMedium: TextStyle(fontSize: 16, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 12, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 10, color: Colors.white),
          bodySmall: TextStyle(fontSize: 8, color: Colors.white70),
          labelLarge: TextStyle(fontSize: 10, color: Colors.white),
          labelMedium: TextStyle(fontSize: 8, color: Colors.white),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // RPG-specific colors
  static const hpBarGreen = Color(0xFF4CAF50);
  static const hpBarYellow = Color(0xFFFFC107);
  static const hpBarRed = Color(0xFFF44336);
  static const mpBarBlue = Color(0xFF2196F3);
  static const xpBarPurple = Color(0xFF9C27B0);
  static const goldColor = Color(0xFFFFD700);
  static const criticalColor = Color(0xFFFFEB3B);
  static const healColor = Color(0xFF66BB6A);
  static const damageColor = Color(0xFFFF5252);
  static const missColor = Color(0xFFB0BEC5);
  static const shieldColor = Color(0xFF42A5F5);
  static const fireColor = Color(0xFFFF6D00);
  static const iceColor = Color(0xFF00BCD4);
  static const physicalColor = Color(0xFFE0E0E0);
  static const poisonColor = Color(0xFF9C27B0);

  static Color hpColor(double percent) {
    if (percent > 0.5) return hpBarGreen;
    if (percent > 0.25) return hpBarYellow;
    return hpBarRed;
  }
}
