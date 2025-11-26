import 'package:flutter/material.dart';

class AppColors {
  // Dark theme colors
  static const background = Color(0xff070b14);
  static const panel = Color(0xff0d1324);
  static const surface = Color(0xff111a2e);
  static const surfaceElevated = Color(0xff15213a);
  static const accent = Color(0xff7c5dfa);
  static const accentAlt = Color(0xff4fd1c5);
  static const outline = Color(0xff1f2a44);
  static const textMuted = Color(0xff9ba4c4);
  static const success = Color(0xff34d399);
  static const danger = Color(0xffff6b6b);
  static const warning = Color(0xfffbbf24);

  // Light theme colors
  static const lightBackground = Color(0xfff8fafc);
  static const lightPanel = Color(0xffffffff);
  static const lightSurface = Color(0xfff1f5f9);
  static const lightSurfaceElevated = Color(0xffffffff);
  static const lightOutline = Color(0xffe2e8f0);
  static const lightTextMuted = Color(0xff64748b);
  static const lightTextPrimary = Color(0xff1e293b);

  // Priority colors
  static const priorityHigh = Color(0xffef4444);
  static const priorityMedium = Color(0xfffbbf24);
  static const priorityLow = Color(0xff22c55e);
}

class AppTheme {
  static ThemeData darkTheme() {
    final colorScheme = const ColorScheme.dark().copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accentAlt,
      surface: AppColors.surface,
      surfaceContainerHighest: AppColors.surfaceElevated,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        labelStyle: const TextStyle(color: Colors.white),
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  static ThemeData lightTheme() {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accentAlt,
      surface: AppColors.lightSurface,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightPanel,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.lightTextMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        labelStyle: const TextStyle(color: AppColors.lightTextPrimary),
        side: const BorderSide(color: AppColors.lightOutline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// Extension to get colors based on theme
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  Color get backgroundColor => isDarkMode ? AppColors.background : AppColors.lightBackground;
  Color get panelColor => isDarkMode ? AppColors.panel : AppColors.lightPanel;
  Color get surfaceColor => isDarkMode ? AppColors.surface : AppColors.lightSurface;
  Color get surfaceElevatedColor => isDarkMode ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;
  Color get outlineColor => isDarkMode ? AppColors.outline : AppColors.lightOutline;
  Color get textMutedColor => isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted;
  Color get textPrimaryColor => isDarkMode ? Colors.white : AppColors.lightTextPrimary;
}
