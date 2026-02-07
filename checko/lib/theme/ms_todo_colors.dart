import 'package:flutter/material.dart';

/// Microsoft To Do Color Scheme
///
/// Pure Microsoft Blue (#2564CF) with clean white/gray design
class MSToDoColors {
  // ==================== PRIMARY COLORS ====================
  /// Microsoft Blue
  static const Color msBlue = Color(0xFF2564CF);
  static const Color msBlueLight = Color(0xFF4A7DD1);
  static const Color msBlueDark = Color(0xFF1A4A9F);

  // ==================== BACKGROUND COLORS ====================
  static const Color msBackground = Color(0xFFF3F2F1);
  static const Color msBackgroundDark = Color(0xFF1F1F1F);

  // ==================== SURFACE COLORS ====================
  static const Color msSurface = Color(0xFFFFFFFF);
  static const Color msSurfaceDark = Color(0xFF2D2D2D);

  // ==================== TEXT COLORS ====================
  static const Color msTextPrimary = Color(0xFF323130);
  static const Color msTextSecondary = Color(0xFF605E5C);
  static const Color msTextPrimaryDark = Color(0xFFFFFFFF);
  static const Color msTextSecondaryDark = Color(0xFFBDBDBD);

  // ==================== BORDER COLORS ====================
  static const Color msBorder = Color(0xFFE1DFDD);
  static const Color msBorderDark = Color(0xFF3D3D3D);

  // ==================== LIST ACCENT COLORS ====================
  static const List<Color> listColors = [
    Color(0xFF2564CF), // Blue
    Color(0xFF0078D4), // Dark Blue
    Color(0xFF008272), // Teal
    Color(0xFF107C10), // Green
    Color(0xFF5C2D91), // Purple
    Color(0xFFD83B01), // Red
    Color(0xFFCA5010), // Orange
    Color(0xFF0078D4), // Light Blue
  ];

  // ==================== MY DAY COLORS ====================
  static const Color myDayAccent = Color(0xFF0078D4);
  static const Color myDayGradientStart = Color(0xFF5A9FD4);
  static const Color myDayGradientEnd = Color(0xFF2564CF);

  // ==================== IMPORTANT COLORS ====================
  static const Color importantAccent = Color(0xFFCA5010);

  // ==================== PLANNED COLORS ====================
  static const Color plannedAccent = Color(0xFF0078D4);

  // ==================== ALL TASKS COLORS ====================
  static const Color allTasksAccent = Color(0xFF008272);

  // ==================== COMPLETED COLORS ====================
  static const Color completedAccent = Color(0xFF605E5C);

  // ==================== SEMANTIC COLORS ====================
  static const Color success = Color(0xFF107C10);
  static const Color warning = Color(0xFFFF8C00);
  static const Color error = Color(0xFFA80000);

  // ==================== PRIORITY COLORS ====================
  static const Color priorityHigh = Color(0xFFA80000);
  static const Color priorityMedium = Color(0xFFFF8C00);
  static const Color priorityLow = Color(0xFF0078D4);

  /// Get list color by index
  static Color getListColor(int index) {
    return listColors[index % listColors.length];
  }
}

/// Extension for checking if dark mode
extension MSThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
