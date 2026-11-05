import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF111215);
  static const Color surface = Color(0xFF1B1C22);
  static const Color surfaceVariant = Color(0xFF262833);
  static const Color cardColor = Color(0xFF20222A);
  
  static const Color primary = Color(0xFFFF334B); // Studio Coral Red
  static const Color primaryVariant = Color(0xFFD32F2F);
  static const Color secondary = Color(0xFF2979FF); // Blue accent
  static const Color accent = Color(0xFFFFB300); // Amber / Highlight
  
  static const Color textPrimary = Color(0xFFF0F1F5);
  static const Color textSecondary = Color(0xFFA0A4B8);
  static const Color textMuted = Color(0xFF6B7085);
  
  static const Color divider = Color(0xFF2D303E);
  static const Color timelineBackground = Color(0xFF14151B);
  static const Color timelineTrack = Color(0xFF1E202A);
  static const Color timelinePrimaryClip = Color(0xFF2E4057);
  static const Color timelineSecondaryClip = Color(0xFF3B3355);
  static const Color timelineTextClip = Color(0xFF2A5248);
  static const Color timelineAudioClip = Color(0xFF4A3E1B);
  static const Color playhead = Color(0xFFFF334B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: cardColor,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceVariant,
        thumbColor: Colors.white,
        overlayColor: primary.withValues(alpha: 0.2),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      useMaterial3: true,
    );
  }
}
