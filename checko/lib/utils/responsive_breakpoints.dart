import 'package:flutter/widgets.dart';

/// Breakpoint categories for responsive design
enum Breakpoint { mobile, tablet, desktop }

/// Responsive breakpoint configuration
///
/// Defines standard breakpoints for adaptive layouts:
/// - Mobile: < 600px (single column, bottom navigation)
/// - Tablet: 600-1200px (two columns, navigation rail)
/// - Desktop: > 1200px (three columns, navigation rail)
class ResponsiveBreakpoints {
  static const double mobileMax = 600;
  static const double tabletMax = 1200;
  static const double desktopMin = 1200;

  /// Get breakpoint from width
  static Breakpoint fromWidth(double width) {
    if (width < mobileMax) return Breakpoint.mobile;
    if (width < tabletMax) return Breakpoint.tablet;
    return Breakpoint.desktop;
  }

  /// Get grid column count for breakpoint
  static int gridColumns(Breakpoint bp) {
    switch (bp) {
      case Breakpoint.mobile:
        return 1;
      case Breakpoint.tablet:
        return 2;
      case Breakpoint.desktop:
        return 3;
    }
  }

  /// Get padding for breakpoint
  static double padding(Breakpoint bp) {
    switch (bp) {
      case Breakpoint.mobile:
        return 16;
      case Breakpoint.tablet:
        return 24;
      case Breakpoint.desktop:
        return 32;
    }
  }

  /// Get max content width for breakpoint
  static double maxContentWidth(Breakpoint bp) {
    switch (bp) {
      case Breakpoint.mobile:
        return double.infinity;
      case Breakpoint.tablet:
        return 900;
      case Breakpoint.desktop:
        return 1200;
    }
  }

  /// Check if breakpoint should use navigation rail (vs bottom bar)
  static bool useNavigationRail(Breakpoint bp) {
    return bp == Breakpoint.tablet || bp == Breakpoint.desktop;
  }

  /// Get calendar grid columns for breakpoint
  static int calendarGridColumns(Breakpoint bp) {
    switch (bp) {
      case Breakpoint.mobile:
        return 7; // Standard week view
      case Breakpoint.tablet:
        return 7;
      case Breakpoint.desktop:
        return 7;
    }
  }

  /// Get item spacing for breakpoint
  static double itemSpacing(Breakpoint bp) {
    switch (bp) {
      case Breakpoint.mobile:
        return 12;
      case Breakpoint.tablet:
        return 16;
      case Breakpoint.desktop:
        return 20;
    }
  }
}

/// Extension on BuildContext for convenient breakpoint access
extension ResponsiveContext on BuildContext {
  /// Get current breakpoint from media query
  Breakpoint get breakpoint {
    final width = MediaQuery.of(this).size.width;
    return ResponsiveBreakpoints.fromWidth(width);
  }

  /// Check if current breakpoint is mobile
  bool get isMobile => breakpoint == Breakpoint.mobile;

  /// Check if current breakpoint is tablet
  bool get isTablet => breakpoint == Breakpoint.tablet;

  /// Check if current breakpoint is desktop
  bool get isDesktop => breakpoint == Breakpoint.desktop;

  /// Check if should use navigation rail
  bool get useNavigationRail => ResponsiveBreakpoints.useNavigationRail(breakpoint);

  /// Get current grid column count
  int get gridColumns => ResponsiveBreakpoints.gridColumns(breakpoint);

  /// Get current padding
  double get responsivePadding => ResponsiveBreakpoints.padding(breakpoint);

  /// Get max content width
  double get maxContentWidth => ResponsiveBreakpoints.maxContentWidth(breakpoint);

  /// Get current item spacing
  double get itemSpacing => ResponsiveBreakpoints.itemSpacing(breakpoint);
}

/// Responsive builder widget that provides breakpoint to builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Breakpoint breakpoint) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, context.breakpoint);
  }
}

/// Widget that shows different children based on breakpoint
class ResponsiveValue<T> extends StatelessWidget {
  final T mobile;
  final T? tablet;
  final T? desktop;
  final Widget Function(BuildContext context, T value) builder;

  const ResponsiveValue({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final bp = context.breakpoint;
    final value = switch (bp) {
      Breakpoint.mobile => mobile,
      Breakpoint.tablet => tablet ?? mobile,
      Breakpoint.desktop => desktop ?? tablet ?? mobile,
    };
    return builder(context, value);
  }
}
