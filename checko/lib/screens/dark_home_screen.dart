import 'package:flutter/material.dart';
import '../theme/dark_modern_theme.dart';
import '../screens/dark_my_day_screen.dart';
import '../screens/dark_important_screen.dart';
import '../screens/dark_planned_screen.dart';
import '../screens/dark_all_tasks_screen.dart';
import '../screens/dark_lists_screen.dart';
import '../screens/dark_calendar_screen.dart';
import '../screens/dark_progress_screen.dart';
import '../screens/dark_settings_screen.dart';
import '../screens/dark_create_task_screen.dart';

/// Dark & Modern Home Screen
///
/// Features:
/// - Responsive navigation (drawer on mobile, rail on larger screens)
/// - Glassmorphism effects
/// - Clear icons and labels
/// - Adaptive layout for different screen sizes
class DarkHomeScreen extends StatefulWidget {
  const DarkHomeScreen({super.key});

  @override
  State<DarkHomeScreen> createState() => _DarkHomeScreenState();
}

class _DarkHomeScreenState extends State<DarkHomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Responsive breakpoint - switch to rail at 600px width
  static const double _navigationRailBreakpoint = 600;

  final List<NavItem> _navItems = [
    NavItem(
      id: 'my_day',
      label: 'My Day',
      icon: Icons.wb_sunny_outlined,
      iconFilled: Icons.wb_sunny,
      color: DarkModernTheme.accentYellow,
    ),
    NavItem(
      id: 'important',
      label: 'Important',
      icon: Icons.star_border_rounded,
      iconFilled: Icons.star_rounded,
      color: DarkModernTheme.accentYellow,
    ),
    NavItem(
      id: 'planned',
      label: 'Planned',
      icon: Icons.calendar_today_outlined,
      iconFilled: Icons.calendar_today,
      color: DarkModernTheme.accentBlue,
    ),
    NavItem(
      id: 'all',
      label: 'All Tasks',
      icon: Icons.checklist_rounded,
      iconFilled: Icons.checklist,
      color: DarkModernTheme.accentGreen,
    ),
    NavItem(
      id: 'lists',
      label: 'Lists',
      icon: Icons.folder_outlined,
      iconFilled: Icons.folder,
      color: DarkModernTheme.accentPurple,
    ),
    NavItem(
      id: 'calendar',
      label: 'Calendar',
      icon: Icons.calendar_month_outlined,
      iconFilled: Icons.calendar_month,
      color: DarkModernTheme.accentBlue,
    ),
    NavItem(
      id: 'progress',
      label: 'Progress',
      icon: Icons.assessment_outlined,
      iconFilled: Icons.assessment,
      color: DarkModernTheme.accentBlue,
    ),
    NavItem(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings_outlined,
      iconFilled: Icons.settings,
      color: DarkModernTheme.accentPink,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use drawer on mobile (< 600px), rail on larger screens
        final useDrawer = constraints.maxWidth < _navigationRailBreakpoint;

        if (useDrawer) {
          // Mobile: Drawer navigation
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: DarkModernTheme.background,
            body: _screens()[_selectedIndex],
            // Right-side drawer
            endDrawer: _buildDrawer(),
            floatingActionButton: FloatingActionButton(
              heroTag: 'fab_home_drawer',
              onPressed: () => _addTask(),
              backgroundColor: DarkModernTheme.primary,
              foregroundColor: Colors.white,
              elevation: 8,
              child: const Icon(Icons.add, size: 28),
            ),
          );
        } else {
          // Desktop/Tablet: Navigation rail on the left
          return Scaffold(
            backgroundColor: DarkModernTheme.background,
            body: Row(
              children: [
                // Left navigation rail
                _buildNavigationRail(),
                // Main content
                Expanded(
                  child: Stack(
                    children: [
                      _screens()[_selectedIndex],
                      // FAB for quick add
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: _buildFAB(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildNavigationRail() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DarkModernTheme.surface.withOpacity(0.9),
            DarkModernTheme.surface.withOpacity(0.7),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // App Logo/Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: DarkModernTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: DarkModernTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
            ),

            const SizedBox(height: 32),

            // Navigation Items
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _navItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isSelected = _selectedIndex == index;

                    return _buildRailNavItem(item, isSelected, index);
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRailNavItem(NavItem item, bool isSelected, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withOpacity(0.25),
                    item.color.withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
          border: isSelected
              ? Border.all(
                  color: item.color.withOpacity(0.4),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.iconFilled : item.icon,
              size: 26,
              color: isSelected ? item.color : DarkModernTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? item.color : DarkModernTheme.textTertiary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      heroTag: 'fab_home_rail',
      onPressed: () => _addTask(),
      backgroundColor: DarkModernTheme.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('New Task'),
    );
  }

  Widget _buildDrawer() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DarkModernTheme.surface.withOpacity(0.95),
            DarkModernTheme.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: DarkModernTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: DarkModernTheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Checko',
                        style: DarkModernTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your Tasks',
                        style: DarkModernTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0x1AFFFFFF)),

            const SizedBox(height: 8),

            // Navigation Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _selectedIndex == index;

                  return _buildDrawerItem(item, isSelected, index);
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(NavItem item, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context); // Close drawer
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withOpacity(0.25),
                    item.color.withOpacity(0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
          border: isSelected
              ? Border.all(
                  color: item.color.withOpacity(0.4),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? item.color.withOpacity(0.2)
                    : item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSelected ? item.iconFilled : item.icon,
                size: 22,
                color: isSelected ? item.color : DarkModernTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? item.color : DarkModernTheme.textPrimary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const DarkCreateTaskScreen(),
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh
    }
  }

  List<Widget> _screens() {
    return [
      const DarkMyDayScreen(),
      const DarkImportantScreen(),
      const DarkPlannedScreen(),
      const DarkAllTasksScreen(),
      const DarkListsScreen(),
      const DarkCalendarScreen(),
      const DarkProgressScreen(),
      const DarkSettingsScreen(),
    ];
  }
}

class NavItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData? iconFilled;
  final Color color;

  NavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.iconFilled,
    required this.color,
  });
}
