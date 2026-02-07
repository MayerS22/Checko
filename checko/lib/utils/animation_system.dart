import 'dart:ui';
import 'package:flutter/material.dart';

/// Application-wide animation configuration
///
/// Provides consistent animation curves, durations, and constants
/// throughout the app for a cohesive feel.
class AppAnimations {
  // ==================== CURVES ====================

  /// Bouncy spring curve for delightful interactions
  /// Based on Material Design spring parameters
  static const Cubic springCurve = Cubic(0.175, 0.885, 0.32, 1.275);

  /// Smooth deceleration curve
  /// Use for entrances and fade-ins
  static const Cubic smoothCurve = Cubic(0.4, 0.0, 0.2, 1);

  /// Sharp, snappy curve for quick interactions
  /// Use for button presses and toggle switches
  static const Cubic sharpCurve = Cubic(0.0, 0.0, 0.2, 1);

  /// Standard ease-in-out curve
  /// Use for general purpose animations
  static const Cubic easeInOut = Cubic(0.4, 0.0, 0.2, 1);

  /// Material design emphasized curve
  /// Use for important transitions
  static const Cubic emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Material design emphasized decelerate curve
  static const Cubic emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Material design emphasized accelerate curve
  static const Cubic emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  // ==================== DURATIONS ====================

  /// Fast duration for micro-interactions
  /// Use for: button presses, hover states, small scale changes
  static const Duration fast = Duration(milliseconds: 150);

  /// Medium duration for standard transitions
  /// Use for: page transitions, modal appearances, list item animations
  static const Duration medium = Duration(milliseconds: 250);

  /// Slow duration for complex animations
  /// Use for: shared element transitions, elaborate transforms
  static const Duration slow = Duration(milliseconds: 350);

  /// Extra slow duration for special animations
  /// Use for: splash screen, onboarding transitions
  static const Duration extraSlow = Duration(milliseconds: 500);

  /// Instant duration for state changes
  static const Duration instant = Duration(milliseconds: 50);

  // ==================== HERO TAGS ====================

  /// Hero tag keys for shared element transitions
  static const String heroEventCard = 'event_card';
  static const String heroTaskItem = 'task_item';
  static const String heroCalendar = 'calendar';
  static const String heroFAB = 'fab';
  static const String heroAvatar = 'avatar';
  static const String heroDialogTitle = 'dialog_title';

  // ==================== SCALE VALUES ====================

  /// Press scale for buttons (shrinks when pressed)
  static const double pressScale = 0.95;

  /// Hover scale for interactive elements
  static const double hoverScale = 1.05;

  /// Selected scale for emphasized state
  static const double selectedScale = 1.1;

  // ==================== OPACITY VALUES ====================

  /// Disabled opacity for non-interactive elements
  static const double disabledOpacity = 0.38;

  /// Hover opacity for subtle feedback
  static const double hoverOpacity = 0.08;

  /// Focus opacity for keyboard navigation
  static const double focusOpacity = 0.12;

  /// Pressed opacity for touch feedback
  static const double pressedOpacity = 0.16;

  /// Drag opacity for drag operations
  static const double dragOpacity = 0.8;

  // ==================== STAGGER DELAYS ====================

  /// Delay between staggered list items
  static const Duration staggerDelay = Duration(milliseconds: 50);

  /// Quick stagger delay for dense lists
  static const Duration quickStaggerDelay = Duration(milliseconds: 25);

  /// Slow stagger delay for sparse lists
  static const Duration slowStaggerDelay = Duration(milliseconds: 75);
}

/// Extension to get appropriate animation duration based on accessibility
extension AnimationDuration on BuildContext {
  /// Returns the duration, or instant if reduced motion is enabled
  Duration getAccessibleDuration(Duration duration) {
    if (MediaQuery.of(this).disableAnimations) {
      return AppAnimations.instant;
    }
    return duration;
  }

  /// Returns the curve, or linear if reduced motion is enabled
  Curve getAccessibleCurve(Curve curve) {
    if (MediaQuery.of(this).disableAnimations) {
      return Curves.linear;
    }
    return curve;
  }

  /// Check if animations are reduced
  bool get isReducedMotion => MediaQuery.of(this).disableAnimations;
}

/// Animated scale widget for tap feedback
class AnimatedScaleOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;
  final Duration duration;
  final Curve curve;

  const AnimatedScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = AppAnimations.pressScale,
    this.duration = AppAnimations.fast,
    this.curve = AppAnimations.springCurve,
  });

  @override
  State<AnimatedScaleOnTap> createState() => _AnimatedScaleOnTapState();
}

class _AnimatedScaleOnTapState extends State<AnimatedScaleOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleAmount,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_isPressed) {
      _isPressed = true;
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      _isPressed = false;
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skip animation if reduced motion is enabled
    if (context.isReducedMotion) {
      return GestureDetector(
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Fade in animation widget
class AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final VoidCallback? onComplete;

  const AnimatedFadeIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.medium,
    this.delay = Duration.zero,
    this.curve = AppAnimations.smoothCurve,
    this.onComplete,
  });

  @override
  State<AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<AnimatedFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });

    // Call on complete when finished
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Skip animation if reduced motion is enabled
    if (context.isReducedMotion) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

/// Slide in animation widget with direction
class AnimatedSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final SlideDirection direction;
  final double beginOffset;
  final VoidCallback? onComplete;

  const AnimatedSlideIn({
    super.key,
    required this.child,
    this.duration = AppAnimations.medium,
    this.delay = Duration.zero,
    this.curve = AppAnimations.smoothCurve,
    this.direction = SlideDirection.up,
    this.beginOffset = 0.3,
    this.onComplete,
  });

  @override
  State<AnimatedSlideIn> createState() => _AnimatedSlideInState();
}

enum SlideDirection { up, down, left, right }

class _AnimatedSlideInState extends State<AnimatedSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    final begin = switch (widget.direction) {
      SlideDirection.up => Offset(0, widget.beginOffset),
      SlideDirection.down => Offset(0, -widget.beginOffset),
      SlideDirection.left => Offset(widget.beginOffset, 0),
      SlideDirection.right => Offset(-widget.beginOffset, 0),
    };

    _slideAnimation = Tween<Offset>(
      begin: begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Skip animation if reduced motion is enabled
    if (context.isReducedMotion) {
      return widget.child;
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer loading placeholder widget
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
