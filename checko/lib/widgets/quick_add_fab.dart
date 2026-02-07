import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/animation_system.dart';
import '../utils/responsive_breakpoints.dart';

/// Quick Add FAB with spring animation
///
/// Shows a main FAB that expands to reveal quick action options:
/// - Add Task
/// - Add Event
/// - Start Focus Mode
/// - Start Pomodoro
class QuickAddFAB extends StatefulWidget {
  final VoidCallback? onAddTask;
  final VoidCallback? onAddEvent;
  final VoidCallback? onStartFocus;
  final VoidCallback? onStartPomodoro;
  final String? tooltip;
  final bool mini;

  const QuickAddFAB({
    super.key,
    this.onAddTask,
    this.onAddEvent,
    this.onStartFocus,
    this.onStartPomodoro,
    this.tooltip,
    this.mini = false,
  });

  @override
  State<QuickAddFAB> createState() => _QuickAddFABState();
}

class _QuickAddFABState extends State<QuickAddFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;

  // Quick action options
  static const List<_QuickAction> _actions = [
    _QuickAction(
      icon: Icons.task_alt,
      label: 'Task',
      color: AppColors.accent,
      gradient: [
        Color(0xFF7C5DFA),
        Color(0xFF6A48E8),
      ],
    ),
    _QuickAction(
      icon: Icons.event,
      label: 'Event',
      color: AppColors.accentAlt,
      gradient: [
        Color(0xFF4FD1C5),
        Color(0xFF00B4A8),
      ],
    ),
    _QuickAction(
      icon: Icons.center_focus_strong,
      label: 'Focus',
      color: AppColors.warning,
      gradient: [
        Color(0xFFFBBF24),
        Color(0xFFE6A800),
      ],
    ),
    _QuickAction(
      icon: Icons.timer,
      label: 'Pomodoro',
      color: AppColors.danger,
      gradient: [
        Color(0xFFFF6B6B),
        Color(0xFFE64646),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.springCurve,
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0.785, // 45 degrees in radians
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.springCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _handleAction(_QuickAction action) {
    _toggleExpanded();

    // Call the appropriate callback
    switch (action.label.toLowerCase()) {
      case 'task':
        widget.onAddTask?.call();
        break;
      case 'event':
        widget.onAddEvent?.call();
        break;
      case 'focus':
        widget.onStartFocus?.call();
        break;
      case 'pomodoro':
        widget.onStartPomodoro?.call();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Skip animation if reduced motion is enabled
    if (context.isReducedMotion) {
      return _buildSimpleFAB(context);
    }

    return SizedBox(
      width: widget.mini ? 40 : 56,
      height: widget.mini ? 40 : 56,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Expanded options
          if (_isExpanded) ...[
            for (int i = 0; i < _actions.length; i++)
              _buildActionItem(_actions[i], i),
          ],

          // Main FAB
          _buildMainFAB(),
        ],
      ),
    );
  }

  Widget _buildMainFAB() {
    final size = widget.mini ? 40.0 : 56.0;

    return FloatingActionButton(
      heroTag: 'quick_add_fab',
      onPressed: _toggleExpanded,
      tooltip: widget.tooltip ?? 'Quick Add',
      mini: widget.mini,
      elevation: _isExpanded ? 8 : 6,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.mini ? 12 : 16),
      ),
      child: AnimatedBuilder(
        animation: _rotateAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotateAnimation.value,
            child: Icon(
              _isExpanded ? Icons.close : Icons.add,
              size: widget.mini ? 20 : 28,
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionItem(_QuickAction action, int index) {
    // Calculate position for circular layout
    final angle = (index * 45) * pi / 180; // 45-degree increments
    final distance = widget.mini ? 50.0 : 70.0; // Distance from center

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;
        final offsetX = -sin(angle) * distance * progress;
        final offsetY = -cos(angle) * distance * progress;

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: progress,
              child: child,
            ),
          ),
        );
      },
      child: _ActionChip(
        action: action,
        mini: widget.mini,
        onTap: () => _handleAction(action),
      ),
    );
  }

  Widget _buildSimpleFAB(BuildContext context) {
    // For reduced motion, show a simple menu
    return FloatingActionButton(
      heroTag: 'quick_add_fab',
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _SimpleQuickActionSheet(
            onAddTask: widget.onAddTask,
            onAddEvent: widget.onAddEvent,
            onStartFocus: widget.onStartFocus,
            onStartPomodoro: widget.onStartPomodoro,
          ),
        );
      },
      tooltip: widget.tooltip ?? 'Quick Add',
      mini: widget.mini,
      elevation: 6,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.mini ? 12 : 16),
      ),
      child: const Icon(Icons.add),
    );
  }
}

/// Quick action definition
class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final List<Color> gradient;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.gradient,
  });
}

/// Action chip for expanded FAB options
class _ActionChip extends StatelessWidget {
  final _QuickAction action;
  final bool mini;
  final VoidCallback onTap;

  const _ActionChip({
    required this.action,
    required this.mini,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = mini ? 36.0 : 48.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: action.gradient,
          ),
          borderRadius: BorderRadius.circular(mini ? 10 : 14),
          boxShadow: [
            BoxShadow(
              color: action.color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          action.icon,
          color: Colors.white,
          size: mini ? 18 : 24,
        ),
      ),
    );
  }
}

/// Simple bottom sheet for reduced motion mode
class _SimpleQuickActionSheet extends StatelessWidget {
  final VoidCallback? onAddTask;
  final VoidCallback? onAddEvent;
  final VoidCallback? onStartFocus;
  final VoidCallback? onStartPomodoro;

  const _SimpleQuickActionSheet({
    required this.onAddTask,
    required this.onAddEvent,
    required this.onStartFocus,
    required this.onStartPomodoro,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Add',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAction(
                context,
                icon: Icons.task_alt,
                label: 'Task',
                color: AppColors.accent,
                onTap: () {
                  Navigator.pop(context);
                  onAddTask?.call();
                },
              ),
              _buildAction(
                context,
                icon: Icons.event,
                label: 'Event',
                color: AppColors.accentAlt,
                onTap: () {
                  Navigator.pop(context);
                  onAddEvent?.call();
                },
              ),
              _buildAction(
                context,
                icon: Icons.center_focus_strong,
                label: 'Focus',
                color: AppColors.warning,
                onTap: () {
                  Navigator.pop(context);
                  onStartFocus?.call();
                },
              ),
              _buildAction(
                context,
                icon: Icons.timer,
                label: 'Pomodoro',
                color: AppColors.danger,
                onTap: () {
                  Navigator.pop(context);
                  onStartPomodoro?.call();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: context.captionStyle,
          ),
        ],
      ),
    );
  }
}

/// Quick Add Button (simpler version, no expansion)
class QuickAddButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const QuickAddButton({
    super.key,
    this.label = 'Add New',
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            )
          : (icon != null ? Icon(icon, size: 18) : null),
      label: Text(label),
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// Speed dial FAB for common actions
class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SpeedDialFAB({
    super.key,
    required this.actions,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.springCurve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Actions
        if (_isExpanded)
          ...widget.actions.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ScaleTransition(
                  scale: _expandAnimation,
                  child: FloatingActionButton.small(
                    heroTag: action.label,
                    onPressed: () {
                      action.onPressed();
                      _toggleExpanded();
                    },
                    backgroundColor: action.color,
                    child: Icon(action.icon),
                  ),
                ),
              )),

        // Main FAB
        FloatingActionButton(
          heroTag: 'speed_dial_main',
          onPressed: _toggleExpanded,
          backgroundColor: widget.backgroundColor ?? AppColors.accent,
          foregroundColor: widget.foregroundColor ?? Colors.white,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: AppAnimations.medium,
            child: Icon(_isExpanded ? Icons.close : (widget.icon ?? Icons.add)),
          ),
        ),
      ],
    );
  }
}

/// Speed dial action
class SpeedDialAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const SpeedDialAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });
}
