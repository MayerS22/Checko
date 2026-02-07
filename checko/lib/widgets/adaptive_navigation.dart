import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/animation_system.dart';

/// Adaptive navigation that switches between:
/// - Bottom navigation bar on mobile
/// - Navigation rail on tablet/desktop
///
/// Follows Material 3 design guidelines.
class AdaptiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final bool extended;
  final Widget? body;

  const AdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.extended = false,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    if (context.useNavigationRail) {
      return _buildNavigationRail(context);
    } else {
      return _buildBottomNavigation(context);
    }
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        animationDuration: AppAnimations.medium,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: extended
                ? NavigationRailLabelType.all
                : (context.isTablet
                    ? NavigationRailLabelType.all
                    : NavigationRailLabelType.selected),
            destinations: destinations
                .map((dest) => NavigationRailDestination(
                      icon: dest.icon,
                      selectedIcon: dest.selectedIcon,
                      label: Text(dest.label),
                    ))
                .toList(),
            extended: extended,
            elevation: 4,
            leading: extended ? null : const SizedBox(height: 56),
            trailing: extended ? null : const SizedBox(height: 56),
            backgroundColor: context.surfaceColor,
            selectedIconTheme: IconThemeData(color: AppColors.accent),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(child: body ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}

/// Custom navigation destination with additional properties
class AppNavigationDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? tooltip;
  final Color? color;

  const AppNavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.color,
  });

  /// Convert to Material NavigationDestination
  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: selectedIcon != null ? Icon(selectedIcon) : null,
      label: label,
      tooltip: tooltip ?? label,
    );
  }
}

/// Adaptive navigation with app-specific styling
class AppAdaptiveNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final List<AppNavigationDestination> destinations;
  final Widget? body;
  final bool showFab;
  final Widget? fab;
  final FloatingActionButtonLocation? fabLocation;

  const AppAdaptiveNavigation({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.destinations,
    this.body,
    this.showFab = false,
    this.fab,
    this.fabLocation,
  });

  @override
  State<AppAdaptiveNavigation> createState() => _AppAdaptiveNavigationState();
}

class _AppAdaptiveNavigationState extends State<AppAdaptiveNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabController, curve: AppAnimations.springCurve),
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Convert destinations to NavigationDestination
    final navigationDestinations = widget.destinations
        .map((dest) => dest.toNavigationDestination())
        .toList();

    if (context.useNavigationRail) {
      return _buildWithRail(context, navigationDestinations);
    } else {
      return _buildWithBottomBar(context, navigationDestinations);
    }
  }

  Widget _buildWithBottomBar(
    BuildContext context,
    List<NavigationDestination> destinations,
  ) {
    return Scaffold(
      body: widget.body,
      floatingActionButton: widget.showFab ? widget.fab : null,
      floatingActionButtonLocation: widget.fabLocation ??
          FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: widget.showFab ? 64 : 0,
            ),
            child: NavigationBar(
              selectedIndex: widget.currentIndex,
              onDestinationSelected: (index) {
                // Animate tab change
                setState(() {
                  widget.onTabChanged(index);
                });
              },
              destinations: destinations,
              animationDuration: AppAnimations.medium,
              height: 65,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithRail(
    BuildContext context,
    List<NavigationDestination> destinations,
  ) {
    final railWidth = context.isTablet ? 80.0 : 56.0;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          Container(
            width: railWidth,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(
                right: BorderSide(
                  color: context.outlineColor,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // App logo/icon
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentAlt],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // Navigation items
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == widget.currentIndex;
                        final destination = widget.destinations[index];

                        return _RailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: destination.label,
                          isSelected: isSelected,
                          color: destination.color,
                          onTap: () => widget.onTabChanged(index),
                        );
                      },
                    ),
                  ),

                  const Divider(height: 1),

                  // Settings (always at bottom)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _RailDestination(
                      icon: Icons.settings_outlined,
                      selectedIcon: Icons.settings,
                      label: 'Settings',
                      isSelected: false,
                      onTap: () {
                        // Navigate to settings
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Stack(
              children: [
                widget.body ?? const SizedBox.shrink(),
                if (widget.showFab && widget.fab != null)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: ScaleTransition(
                      scale: _fabAnimation,
                      child: widget.fab!,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation rail destination item
class _RailDestination extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _RailDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isSelected ? AppColors.accent : context.textMutedColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accent.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? (selectedIcon ?? icon) : icon,
                  color: effectiveColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Common navigation destinations for the app
class AppNavigationDestinations {
  static const List<AppNavigationDestination> main = [
    AppNavigationDestination(
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt,
      label: 'Tasks',
    ),
    AppNavigationDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Calendar',
    ),
    AppNavigationDestination(
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      label: 'Progress',
    ),
    AppNavigationDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  static const List<AppNavigationDestination> home = [
    AppNavigationDestination(
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt,
      label: 'Tasks',
    ),
    AppNavigationDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Calendar',
    ),
    AppNavigationDestination(
      icon: Icons.show_chart_outlined,
      selectedIcon: Icons.show_chart,
      label: 'Progress',
    ),
  ];

  static const List<AppNavigationDestination> quickActions = [
    AppNavigationDestination(
      icon: Icons.wb_sunny_outlined,
      selectedIcon: Icons.wb_sunny,
      label: 'Focus',
    ),
    AppNavigationDestination(
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
      label: 'Pomodoro',
    ),
    AppNavigationDestination(
      icon: Icons.star_border,
      selectedIcon: Icons.star,
      label: 'Favorites',
    ),
  ];
}
