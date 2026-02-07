import 'package:flutter/material.dart';

import 'ms_todo_colors.dart' as ms_colors;

/// Material 3 Color System for Checko
///
/// Implements tonal palettes and surface container system
/// following Material Design 3 guidelines.
class AppColors {
  // ==================== PRIMARY PALETTE ====================
  /// Primary tonal palette (Purple)
  static const int _primaryValue = 0xFF7C5DFA;

  static const MaterialColor primary = MaterialColor(
    _primaryValue,
    <int, Color>{
      0: Color(0xFFE8E8FF), // Primary 0
      10: Color(0xFFD3D2FF), // Primary 10
      20: Color(0xFFB8B6FF), // Primary 20
      30: Color(0xFF9E9BFF), // Primary 30
      40: Color(0xFF8580FF), // Primary 40
      50: Color(0xFF7C5DFA), // Primary 50 (main)
      60: Color(0xFF6A48E8), // Primary 60
      70: Color(0xFF543BD0), // Primary 70
      80: Color(0xFF3E2FB8), // Primary 80
      90: Color(0xFF2A25A0), // Primary 90
      95: Color(0xFF201B8B), // Primary 95
      99: Color(0xFF160E66), // Primary 99
      100: Color(0xFF0D0741), // Primary 100
    },
  );

  // ==================== SECONDARY PALETTE ====================
  /// Secondary tonal palette (Teal)
  static const int _secondaryValue = 0xFF4FD1C5;

  static const MaterialColor secondary = MaterialColor(
    _secondaryValue,
    <int, Color>{
      0: Color(0xFFD0FBF6),
      10: Color(0xFFA5F5EC),
      20: Color(0xFF7BEFE2),
      30: Color(0xFF56E9D9),
      40: Color(0xFF4FD1C5), // Secondary 40 (main)
      50: Color(0xFF00B4A8),
      60: Color(0xFF008E89),
      70: Color(0xFF006A68),
      80: Color(0xFF004949),
      90: Color(0xFF002A2B),
      95: Color(0xFF001918),
      99: Color(0xFF000808),
      100: Color(0xFF000000),
    },
  );

  // ==================== TERTIARY PALETTE ====================
  /// Tertiary tonal palette (Warm Orange)
  static const int _tertiaryValue = 0xFFFFB84D;

  static const MaterialColor tertiary = MaterialColor(
    _tertiaryValue,
    <int, Color>{
      0: Color(0xFFFFECD8),
      10: Color(0xFFFFD0AA),
      20: Color(0xFFFFB47D),
      30: Color(0xFFFF9A52),
      40: Color(0xFFFFB84D), // Tertiary 40 (main)
      50: Color(0xFFE68A00),
      60: Color(0xFFBA6C00),
      70: Color(0xFF8E5000),
      80: Color(0xFF653700),
      90: Color(0xFF422500),
      95: Color(0xFF2E1600),
      99: Color(0xFF1A0B00),
      100: Color(0xFF0D0400),
    },
  );

  // ==================== ERROR PALETTE ====================
  /// Error tonal palette
  static const int _errorValue = 0xFFFF6B6B;

  static const MaterialColor error = MaterialColor(
    _errorValue,
    <int, Color>{
      0: Color(0xFFFFEAEA),
      10: Color(0xFFFFCECE),
      20: Color(0xFFFFB3B3),
      30: Color(0xFFFF9797),
      40: Color(0xFFFF7B7B),
      50: Color(0xFFFF6B6B), // Error 50 (main)
      60: Color(0xFFE64646),
      70: Color(0xFFC02626),
      80: Color(0xFF9C0808),
      90: Color(0xFF7D0000),
      95: Color(0xFF5F0000),
      99: Color(0xFF420101),
      100: Color(0xFF270000),
    },
  );

  // ==================== NEUTRAL PALETTE ====================
  /// Neutral tonal palette (Dark theme base)
  static const int _neutralValue = 0xFF1A1B26;

  static const MaterialColor neutral = MaterialColor(
    _neutralValue,
    <int, Color>{
      0: Color(0xFF1A1B26),
      10: Color(0xFF282936),
      20: Color(0xFF363847),
      30: Color(0xFF444758),
      40: Color(0xFF53576A),
      50: Color(0xFF62687C),
      60: Color(0xFF72798F),
      70: Color(0xFF828AA3),
      80: Color(0xFF929CB7),
      90: Color(0xFFA3ADCC),
      95: Color(0xFFAEB5D4),
      99: Color(0xFFBBB8DC),
      100: Color(0xFFE8E8FF),
    },
  );

  /// Neutral variant tonal palette
  static const int _neutralVariantValue = 0xFF5C5F72;

  static const MaterialColor neutralVariant = MaterialColor(
    _neutralVariantValue,
    <int, Color>{
      0: Color(0xFFDCE2F9),
      10: Color(0xFFC0C6DC),
      20: Color(0xFFA5ABBE),
      30: Color(0xFF8A90A1),
      40: Color(0xFF707585),
      50: Color(0xFF5C5F72),
      60: Color(0xFF484A5C),
      70: Color(0xFF353646),
      80: Color(0xFF22232F),
      90: Color(0xFF11131D),
      95: Color(0xFF0B0D15),
      99: Color(0xFF050608),
      100: Color(0xFF000000),
    },
  );

  // ==================== LEGACY COLORS (for backward compatibility) ====================
  @deprecated
  static const accent = Color(0xff7c5dfa);
  @deprecated
  static const accentAlt = Color(0xff4fd1c5);
  @deprecated
  static const success = Color(0xff34d399);
  @deprecated
  static const danger = Color(0xffff6b6b);
  @deprecated
  static const warning = Color(0xfffbbf24);

  // ==================== PRIORITY COLORS ====================
  static const Color priorityHigh = Color(0xffef4444);
  static const Color priorityMedium = Color(0xfffbbf24);
  static const Color priorityLow = Color(0xff22c55e);

  // ==================== DARK THEME COLORS ====================
  static const Color backgroundDark = Color(0xff070b14);
  static const Color panelDark = Color(0xff0d1324);
  static const Color surfaceDark = Color(0xff111a2e);
  static const Color surfaceElevatedDark = Color(0xff15213a);
  static const Color outlineDark = Color(0xff1f2a44);
  static const Color textMutedDark = Color(0xff9ba4c4);

  // ==================== LIGHT THEME COLORS ====================
  static const Color backgroundLight = Color(0xfff8fafc);
  static const Color panelLight = Color(0xffffffff);
  static const Color surfaceLight = Color(0xfff1f5f9);
  static const Color surfaceElevatedLight = Color(0xffffffff);
  static const Color outlineLight = Color(0xffe2e8f0);
  static const Color textMutedLight = Color(0xff64748b);
  static const Color textPrimaryLight = Color(0xff1e293b);

  // ==================== SURFACE CONTAINERS (Material 3) ====================
  /// Surface container colors for elevation hierarchy
  static const Color surfaceContainerLowestDark = Color(0xFF0B0E15);
  static const Color surfaceContainerLowDark = Color(0xFF0F131E);
  static const Color surfaceContainerDark = Color(0xFF141826);
  static const Color surfaceContainerHighDark = Color(0xFF1A1E30);
  static const Color surfaceContainerHighestDark = Color(0xFF1F2439);

  static const Color surfaceContainerLowestLight = Color(0xFFF5F7FA);
  static const Color surfaceContainerLowLight = Color(0xFFEFF2F6);
  static const Color surfaceContainerLight = Color(0xFFE8EDF3);
  static const Color surfaceContainerHighLight = Color(0xFFDDE4EB);
  static const Color surfaceContainerHighestLight = Color(0xFFD2DAE3);

  // ==================== SEMANTIC COLORS ====================
  /// Success colors for completed states
  static const Color successLight = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF34D399);

  /// Warning colors for attention
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFFCD34D);

  /// Info colors for informational messages
  static const Color infoLight = Color(0xFF3B82F6);
  static const Color infoDark = Color(0xFF60A5FA);

  /// Error colors for destructive actions
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);
}

/// App Theme Data generator
class AppTheme {
  /// Create Microsoft To Do style light theme
  static ThemeData msToDoLightTheme() {
    final colorScheme = const ColorScheme.light(
      primary: ms_colors.MSToDoColors.msBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE1DFDD),
      onPrimaryContainer: ms_colors.MSToDoColors.msTextPrimary,
      secondary: ms_colors.MSToDoColors.msBlueLight,
      onSecondary: Colors.white,
      background: ms_colors.MSToDoColors.msBackground,
      onBackground: ms_colors.MSToDoColors.msTextPrimary,
      surface: ms_colors.MSToDoColors.msSurface,
      onSurface: ms_colors.MSToDoColors.msTextPrimary,
      error: ms_colors.MSToDoColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ms_colors.MSToDoColors.msBackground,
      cardColor: ms_colors.MSToDoColors.msSurface,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: ms_colors.MSToDoColors.msSurface,
        foregroundColor: ms_colors.MSToDoColors.msTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: ms_colors.MSToDoColors.msTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Navigation Rail Theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: ms_colors.MSToDoColors.msSurface,
        selectedIconTheme: const IconThemeData(color: ms_colors.MSToDoColors.msBlue),
        unselectedIconTheme: IconThemeData(
          color: ms_colors.MSToDoColors.msTextSecondary.withOpacity(0.7),
        ),
        selectedLabelTextStyle: const TextStyle(
          color: ms_colors.MSToDoColors.msBlue,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: ms_colors.MSToDoColors.msTextSecondary.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
        elevation: 1,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: ms_colors.MSToDoColors.msBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: ms_colors.MSToDoColors.msBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: ms_colors.MSToDoColors.msBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: ms_colors.MSToDoColors.msSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: ms_colors.MSToDoColors.msBorder, width: 1),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        iconColor: ms_colors.MSToDoColors.msTextSecondary,
        textColor: ms_colors.MSToDoColors.msTextPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: ms_colors.MSToDoColors.msBorder,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: ms_colors.MSToDoColors.msTextSecondary.withOpacity(0.7),
        size: 24,
      ),

      // Text Theme
      textTheme: _buildMsToDoLightTextTheme(),
    );
  }

  /// Create Microsoft To Do style dark theme
  static ThemeData msToDoDarkTheme() {
    final colorScheme = const ColorScheme.dark(
      primary: ms_colors.MSToDoColors.msBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF2D2D2D),
      onPrimaryContainer: ms_colors.MSToDoColors.msTextPrimaryDark,
      secondary: ms_colors.MSToDoColors.msBlueLight,
      onSecondary: Colors.white,
      background: ms_colors.MSToDoColors.msBackgroundDark,
      onBackground: ms_colors.MSToDoColors.msTextPrimaryDark,
      surface: ms_colors.MSToDoColors.msSurfaceDark,
      onSurface: ms_colors.MSToDoColors.msTextPrimaryDark,
      error: ms_colors.MSToDoColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ms_colors.MSToDoColors.msBackgroundDark,
      cardColor: ms_colors.MSToDoColors.msSurfaceDark,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: ms_colors.MSToDoColors.msSurfaceDark,
        foregroundColor: ms_colors.MSToDoColors.msTextPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: ms_colors.MSToDoColors.msTextPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Navigation Rail Theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: ms_colors.MSToDoColors.msSurfaceDark,
        selectedIconTheme: const IconThemeData(color: ms_colors.MSToDoColors.msBlue),
        unselectedIconTheme: IconThemeData(
          color: ms_colors.MSToDoColors.msTextSecondaryDark.withOpacity(0.7),
        ),
        selectedLabelTextStyle: const TextStyle(
          color: ms_colors.MSToDoColors.msBlue,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: ms_colors.MSToDoColors.msTextSecondaryDark.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
        elevation: 1,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: ms_colors.MSToDoColors.msBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: ms_colors.MSToDoColors.msBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: ms_colors.MSToDoColors.msBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: ms_colors.MSToDoColors.msSurfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: ms_colors.MSToDoColors.msBorderDark, width: 1),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        iconColor: ms_colors.MSToDoColors.msTextSecondaryDark,
        textColor: ms_colors.MSToDoColors.msTextPrimaryDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: ms_colors.MSToDoColors.msBorderDark,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: ms_colors.MSToDoColors.msTextSecondaryDark.withOpacity(0.7),
        size: 24,
      ),

      // Text Theme
      textTheme: _buildMsToDoDarkTextTheme(),
    );
  }

  /// Build Microsoft To Do light text theme
  static TextTheme _buildMsToDoLightTextTheme() {
    return TextTheme(
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: ms_colors.MSToDoColors.msTextPrimary,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ms_colors.MSToDoColors.msTextPrimary,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: ms_colors.MSToDoColors.msTextPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ms_colors.MSToDoColors.msTextPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ms_colors.MSToDoColors.msTextSecondary,
      ),
    );
  }

  /// Build Microsoft To Do dark text theme
  static TextTheme _buildMsToDoDarkTextTheme() {
    return TextTheme(
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: ms_colors.MSToDoColors.msTextPrimaryDark,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: ms_colors.MSToDoColors.msTextPrimaryDark,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: ms_colors.MSToDoColors.msTextPrimaryDark,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ms_colors.MSToDoColors.msTextPrimaryDark,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: ms_colors.MSToDoColors.msTextSecondaryDark,
      ),
    );
  }

  /// Create dark theme with Material 3
  static ThemeData darkTheme() {
    final colorScheme = _createDarkColorScheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceDark,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.textMutedDark,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Navigation Rail Theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textMutedDark,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textMutedDark,
          fontWeight: FontWeight.w500,
        ),
        elevation: 4,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLowDark,
        labelStyle: const TextStyle(color: Colors.white),
        side: const BorderSide(color: AppColors.outlineDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.panelDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outlineDark, width: 1),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textMutedDark,
        textColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineDark,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textMutedDark,
        size: 24,
      ),

      // Text Theme
      textTheme: _createDarkTextTheme(colorScheme),

      // Badge Theme
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.primary,
        textColor: Colors.white,
        smallSize: 8,
        largeSize: 16,
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.panelDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        elevation: 16,
      ),
    );
  }

  /// Create light theme with Material 3
  static ThemeData lightTheme() {
    final colorScheme = _createLightColorScheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      cardColor: AppColors.surfaceLight,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.panelLight,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.textMutedLight,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Navigation Rail Theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textMutedLight,
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textMutedLight,
          fontWeight: FontWeight.w500,
        ),
        elevation: 4,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.outlineLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerLowLight,
        labelStyle: const TextStyle(color: AppColors.textPrimaryLight),
        side: const BorderSide(color: AppColors.outlineLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.panelLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.outlineLight, width: 1),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textMutedLight,
        textColor: AppColors.textPrimaryLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineLight,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textMutedLight,
        size: 24,
      ),

      // Text Theme
      textTheme: _createLightTextTheme(colorScheme),

      // Badge Theme
      badgeTheme: BadgeThemeData(
        backgroundColor: colorScheme.primary,
        textColor: Colors.white,
        smallSize: 8,
        largeSize: 16,
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimaryLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.panelLight,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        elevation: 16,
      ),
    );
  }

  /// Create dark color scheme
  static ColorScheme _createDarkColorScheme() {
    return const ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF3E2FB8),
      onPrimaryContainer: Color(0xFFE8E8FF),

      secondary: AppColors.accentAlt,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF006A68),
      onSecondaryContainer: Color(0xFFD0FBF6),

      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF8E5000),
      onTertiaryContainer: Color(0xFFFFECD8),

      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: Color(0xFF9C0808),
      onErrorContainer: Color(0xFFFFEAEA),

      background: AppColors.backgroundDark,
      onBackground: Colors.white,

      surface: AppColors.surfaceDark,
      onSurface: Colors.white,
      surfaceVariant: AppColors.surfaceContainerLowDark,
      onSurfaceVariant: AppColors.textMutedDark,

      outline: AppColors.outlineDark,
      outlineVariant: Color(0xFF363847),

      shadow: Colors.black,
      scrim: Colors.black54,

      inverseSurface: Color(0xFF2E3145),
      onInverseSurface: Color(0xFFEFF2F6),

      inversePrimary: Color(0xFF9E9BFF),
    );
  }

  /// Create light color scheme
  static ColorScheme _createLightColorScheme() {
    return const ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFB8B6FF),
      onPrimaryContainer: Color(0xFF201B8B),

      secondary: AppColors.accentAlt,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF7BEFE2),
      onSecondaryContainer: Color(0xFF002A2B),

      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFD0AA),
      onTertiaryContainer: Color(0xFF2E1600),

      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: Color(0xFFFFB3B3),
      onErrorContainer: Color(0xFF5F0000),

      background: AppColors.backgroundLight,
      onBackground: AppColors.textPrimaryLight,

      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceVariant: AppColors.surfaceContainerLowLight,
      onSurfaceVariant: AppColors.textMutedLight,

      outline: AppColors.outlineLight,
      outlineVariant: Color(0xFFA5ABBE),

      shadow: Colors.black26,
      scrim: Colors.black54,

      inverseSurface: Color(0xFF1A1B26),
      onInverseSurface: Color(0xFFE8E8FF),

      inversePrimary: Color(0xFF543BD0),
    );
  }

  /// Create dark text theme
  static TextTheme _createDarkTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: const TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      displayMedium: const TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      displaySmall: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Colors.white70,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMutedDark,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMutedDark,
      ),
    );
  }

  /// Create light text theme
  static TextTheme _createLightTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: const TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
      ),
      displayMedium: const TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
      ),
      displaySmall: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
      ),
      headlineLarge: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      headlineMedium: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMutedLight,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMutedLight,
      ),
    );
  }
}

/// Extension for easy color access based on theme
extension ThemeColors on BuildContext {
  /// Check if current theme is dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Background color based on theme
  Color get backgroundColor =>
      isDarkMode ? AppColors.backgroundDark : AppColors.backgroundLight;

  /// Panel/surface color based on theme
  Color get panelColor =>
      isDarkMode ? AppColors.panelDark : AppColors.panelLight;

  /// Surface color based on theme
  Color get surfaceColor =>
      isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;

  /// Elevated surface color based on theme
  Color get surfaceElevatedColor =>
      isDarkMode ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight;

  /// Surface container low color based on theme
  Color get surfaceContainerLowColor =>
      isDarkMode
          ? AppColors.surfaceContainerLowDark
          : AppColors.surfaceContainerLowLight;

  /// Surface container color based on theme
  Color get surfaceContainerColor =>
      isDarkMode
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainerLight;

  /// Surface container high color based on theme
  Color get surfaceContainerHighColor =>
      isDarkMode
          ? AppColors.surfaceContainerHighDark
          : AppColors.surfaceContainerHighLight;

  /// Surface container highest color based on theme
  Color get surfaceContainerHighestColor =>
      isDarkMode
          ? AppColors.surfaceContainerHighestDark
          : AppColors.surfaceContainerHighestLight;

  /// Outline color based on theme
  Color get outlineColor =>
      isDarkMode ? AppColors.outlineDark : AppColors.outlineLight;

  /// Text muted color based on theme
  Color get textMutedColor =>
      isDarkMode ? AppColors.textMutedDark : AppColors.textMutedLight;

  /// Text primary color based on theme
  Color get textPrimaryColor =>
      isDarkMode ? Colors.white : AppColors.textPrimaryLight;

  /// Success color based on theme
  Color get successColor =>
      isDarkMode ? AppColors.successDark : AppColors.successLight;

  /// Warning color based on theme
  Color get warningColor =>
      isDarkMode ? AppColors.warningDark : AppColors.warningLight;

  /// Info color based on theme
  Color get infoColor =>
      isDarkMode ? AppColors.infoDark : AppColors.infoLight;

  /// Error color based on theme
  Color get errorColor =>
      isDarkMode ? AppColors.errorDark : AppColors.errorLight;

  /// Text styles based on theme
  TextStyle get headingStyle => Theme.of(this).textTheme.headlineMedium!;
  TextStyle get subheadingStyle => Theme.of(this).textTheme.titleLarge!;
  TextStyle get bodyStyle => Theme.of(this).textTheme.bodyMedium!;
  TextStyle get captionStyle => Theme.of(this).textTheme.bodySmall!;
  TextStyle get buttonStyle => Theme.of(this).textTheme.labelLarge!;
}
