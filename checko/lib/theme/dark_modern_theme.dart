import 'package:flutter/material.dart';

/// Dark & Modern Theme (Linear/Morph style)
///
/// Features:
/// - Glassmorphism effects (blur, transparency)
/// - Subtle gradients
/// - Dark theme focused
/// - Premium feel
class DarkModernTheme {
  // ==================== PRIMARY COLORS ====================
  static const Color primary = Color(0xFF6366F1); // Indigo/Purple
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // ==================== BACKGROUND COLORS ====================
  static const Color background = Color(0xFF0F0F0F); // Deep black
  static const Color surface = Color(0xFF1A1A1A); // Slightly lighter
  static const Color surfaceGlass = Color(0xCC1A1A1A); // Glass effect

  // ==================== TEXT COLORS ====================
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textTertiary = Color(0xFF71717A);

  // ==================== ACCENT COLORS ====================
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentYellow = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPink = Color(0xFFEC4899);

  // ==================== GRADIENTS ====================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF252525)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCC1E1E1E), Color(0xCC252525)],
  );

  // ==================== BLUR EFFECTS ====================
  static const double blurSmall = 5.0;
  static const double blurMedium = 10.0;
  static const double blurLarge = 20.0;

  // ==================== SPACING ====================
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;

  // ==================== BORDER RADIUS ====================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // ==================== CREATE THEME DATA ====================
  static ThemeData createTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      appBarTheme: _appBarTheme,
      navigationBarTheme: _navigationBarTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputDecorationTheme,
      textTheme: _textTheme,
    );
  }

  // Non-null text style getters
  static TextStyle get titleLarge => _textTheme.titleLarge ?? const TextStyle();
  static TextStyle get titleMedium => _textTheme.titleMedium ?? const TextStyle();
  static TextStyle get bodyLarge => _textTheme.bodyLarge ?? const TextStyle();
  static TextStyle get bodyMedium => _textTheme.bodyMedium ?? const TextStyle();
  static TextStyle get bodySmall => _textTheme.bodySmall ?? const TextStyle();

  static const ColorScheme _colorScheme = ColorScheme.dark(
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF4F46E5),
    onPrimaryContainer: Colors.white,
    secondary: accentPurple,
    onSecondary: Colors.white,
    surface: surface,
    onSurface: textPrimary,
    background: background,
    onBackground: textPrimary,
    error: accentRed,
    onError: Colors.white,
  );

  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    iconTheme: IconThemeData(
      color: textSecondary,
      size: 22,
    ),
  );

  static const NavigationBarThemeData _navigationBarTheme = NavigationBarThemeData(
    backgroundColor: Color(0xCC1A1A1A),
    elevation: 0,
    indicatorColor: primary,
    labelTextStyle: MaterialStatePropertyAll(
      TextStyle(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    iconTheme: MaterialStatePropertyAll(
      IconThemeData(
        color: textSecondary,
        size: 24,
      ),
    ),
  );

  static final FloatingActionButtonThemeData _floatingActionButtonTheme = FloatingActionButtonThemeData(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  static CardThemeData _cardTheme = CardThemeData(
    color: surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
    ),
  );

  static InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF252525),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSmall),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSmall),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSmall),
      borderSide: const BorderSide(color: primary),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    hintStyle: const TextStyle(
      color: textSecondary,
      fontSize: 15,
    ),
  );

  static const TextTheme _textTheme = TextTheme(
    headlineLarge: TextStyle(
      color: textPrimary,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    headlineMedium: TextStyle(
      color: textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      color: textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    titleMedium: TextStyle(
      color: textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    bodyLarge: TextStyle(
      color: textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.1,
    ),
    bodyMedium: TextStyle(
      color: textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.1,
    ),
    bodySmall: TextStyle(
      color: textTertiary,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.1,
    ),
    labelLarge: TextStyle(
      color: textPrimary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
  );
}

/// Glassmorphism Container Widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur = DarkModernTheme.blurMedium,
    this.opacity = 0.8,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        color: DarkModernTheme.surface.withOpacity(opacity),
        borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: blur * 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium - 4),
        child: child,
      ),
    );
  }
}

/// Glassmorphism Card Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? accentColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor?.withOpacity(0.2) ?? DarkModernTheme.primary.withOpacity(0.2),
            accentColor?.withOpacity(0.05) ?? DarkModernTheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
        border: Border.all(
          color: (accentColor ?? DarkModernTheme.primary).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
