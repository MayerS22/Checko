import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lists_screen.dart';
import 'calendar_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'focus_screen.dart';
import 'pomodoro_screen.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _screens = const [
    ListsScreen(),
    CalendarScreen(),
    ProgressScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Update streak when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().updateStreak();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      _animationController.forward().then((_) {
        setState(() {
          _selectedIndex = index;
        });
        _animationController.reverse();
      });
    }
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.panelColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(
                  icon: Icons.wb_sunny,
                  label: 'Focus Mode',
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FocusScreen()),
                    );
                  },
                ),
                _buildQuickAction(
                  icon: Icons.timer,
                  label: 'Pomodoro',
                  color: AppColors.danger,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PomodoroScreen()),
                    );
                  },
                ),
                _buildQuickAction(
                  icon: Icons.star,
                  label: 'Favorites',
                  color: AppColors.accentAlt,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                    );
                  },
                ),
                _buildQuickAction(
                  icon: Icons.settings,
                  label: 'Settings',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: context.textMutedColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.task_alt,
                  label: 'Tasks',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.calendar_month,
                  label: 'Calendar',
                  index: 1,
                ),
                _buildCenterFAB(),
                _buildNavItem(
                  icon: Icons.show_chart,
                  label: 'Progress',
                  index: 2,
                ),
                _buildNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  index: -1,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterFAB() {
    return GestureDetector(
      onTap: _showQuickActions,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.accentAlt],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.apps,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentAlt],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : context.textMutedColor,
                size: 24,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
