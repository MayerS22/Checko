import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../theme/ms_todo_colors.dart';
import 'my_day_screen.dart';
import 'smart_list_screen.dart';
import 'todo_list_screen.dart';
import 'calendar_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

/// Microsoft To Do style navigation item
enum NavItemType {
  myDay,
  important,
  planned,
  all,
  completed,
  calendar,
  progress,
  settings,
  customList,
}

/// Navigation item data
class NavItem {
  final String id;
  final String label;
  final IconData icon;
  final NavItemType type;
  final int? order;

  NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.type,
    this.order,
  });
}

class MSHomeScreen extends StatefulWidget {
  const MSHomeScreen({super.key});

  @override
  State<MSHomeScreen> createState() => _MSHomeScreenState();
}

class _MSHomeScreenState extends State<MSHomeScreen> {
  int _selectedIndex = 0;
  late List<NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = _buildNavItems();
  }

  List<NavItem> _buildNavItems() {
    return [
      NavItem(
        id: 'my_day',
        label: 'My Day',
        icon: Icons.wb_sunny,
        type: NavItemType.myDay,
        order: 0,
      ),
      NavItem(
        id: 'important',
        label: 'Important',
        icon: Icons.star,
        type: NavItemType.important,
        order: 1,
      ),
      NavItem(
        id: 'planned',
        label: 'Planned',
        icon: Icons.calendar_today,
        type: NavItemType.planned,
        order: 2,
      ),
      NavItem(
        id: 'all',
        label: 'All',
        icon: Icons.layers,
        type: NavItemType.all,
        order: 3,
      ),
      NavItem(
        id: 'completed',
        label: 'Completed',
        icon: Icons.check_circle,
        type: NavItemType.completed,
        order: 4,
      ),
      NavItem(
        id: 'calendar',
        label: 'Calendar',
        icon: Icons.calendar_month,
        type: NavItemType.calendar,
        order: 5,
      ),
      NavItem(
        id: 'progress',
        label: 'Progress',
        icon: Icons.show_chart,
        type: NavItemType.progress,
        order: 6,
      ),
      NavItem(
        id: 'settings',
        label: 'Settings',
        icon: Icons.settings,
        type: NavItemType.settings,
        order: 7,
      ),
    ];
  }

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildContentForIndex(int index) {
    if (index >= _navItems.length) {
      return const SizedBox();
    }

    final navItem = _navItems[index];
    final dataProvider = context.watch<DataProvider>();

    switch (navItem.type) {
      case NavItemType.myDay:
        return const MyDayScreen();
      case NavItemType.important:
        return SmartListScreen(
          title: 'Important',
          icon: Icons.star,
          color: MSToDoColors.importantAccent,
          getTodos: () => dataProvider.todos
              .where((t) => t.isFavorite && !t.isCompleted)
              .toList(),
        );
      case NavItemType.planned:
        return SmartListScreen(
          title: 'Planned',
          icon: Icons.calendar_today,
          color: MSToDoColors.plannedAccent,
          getTodos: () => dataProvider.todos
              .where((t) => t.dueDate != null && !t.isCompleted)
              .toList(),
        );
      case NavItemType.all:
        return SmartListScreen(
          title: 'All',
          icon: Icons.layers,
          color: MSToDoColors.allTasksAccent,
          getTodos: () => dataProvider.todos
              .where((t) => !t.isCompleted)
              .toList(),
        );
      case NavItemType.completed:
        return SmartListScreen(
          title: 'Completed',
          icon: Icons.check_circle,
          color: MSToDoColors.completedAccent,
          getTodos: () => dataProvider.todos
              .where((t) => t.isCompleted)
              .toList(),
        );
      case NavItemType.calendar:
        return const CalendarScreen();
      case NavItemType.progress:
        return const ProgressScreen();
      case NavItemType.settings:
        return const SettingsScreen();
      case NavItemType.customList:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use NavigationRail for wider screens, NavigationDrawer for mobile
    if (screenWidth > 600) {
      return _buildWithNavigationRail(isDark);
    } else {
      return _buildWithNavigationDrawer(isDark);
    }
  }

  Widget _buildWithNavigationRail(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? MSToDoColors.msBackgroundDark : MSToDoColors.msBackground,
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            backgroundColor: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onNavItemSelected,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                children: [
                  Text(
                    'Checko',
                    style: TextStyle(
                      color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            destinations: _navItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.icon),
                label: Text(item.label),
              );
            }).toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildNewListButton(isDark),
                ),
              ),
            ),
          ),
          // Vertical divider
          Container(
            width: 1,
            color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
          ),
          // Main content
          Expanded(
            child: _buildContentForIndex(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildWithNavigationDrawer(bool isDark) {
    final selectedItem = _selectedIndex < _navItems.length ? _navItems[_selectedIndex] : null;

    return Scaffold(
      backgroundColor: isDark ? MSToDoColors.msBackgroundDark : MSToDoColors.msBackground,
      drawer: _buildNavigationDrawer(isDark),
      appBar: AppBar(
        backgroundColor: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          selectedItem?.label ?? 'Checko',
          style: TextStyle(
            color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (selectedItem?.type == NavItemType.myDay)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Add task functionality
              },
            ),
        ],
      ),
      body: _buildContentForIndex(_selectedIndex),
    );
  }

  Widget _buildNavigationDrawer(bool isDark) {
    final dataProvider = context.watch<DataProvider>();
    final customLists = dataProvider.todoLists
        .where((l) => !_isDefaultList(l.name))
        .toList();

    return Drawer(
      backgroundColor: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Checko',
                style: TextStyle(
                  color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            // Navigation items
            Expanded(
              child: ListView(
                children: [
                  // All nav items EXCEPT settings
                  ..._navItems.where((item) => item.type != NavItemType.settings).map((item) {
                    final index = _navItems.indexOf(item);
                    return _buildDrawerNavItem(
                      item: item,
                      isDark: isDark,
                      isSelected: _selectedIndex == index,
                      onTap: () {
                        Navigator.pop(context);
                        _onNavItemSelected(index);
                      },
                    );
                  }),
                  // Divider
                  const Divider(),
                  // Custom lists header (only show if there are custom lists)
                  if (customLists.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Lists',
                        style: TextStyle(
                          color: MSToDoColors.msTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  // Custom lists
                  ...customLists.map((list) {
                    return _buildCustomListNavItem(list, isDark);
                  }),
                  // New list button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildNewListButton(isDark),
                  ),
                  // Divider
                  const Divider(),
                  // Settings at the bottom
                  _buildDrawerNavItem(
                    item: _navItems.firstWhere((item) => item.type == NavItemType.settings),
                    isDark: isDark,
                    isSelected: _selectedIndex == _navItems.indexWhere((item) => item.type == NavItemType.settings),
                    onTap: () {
                      Navigator.pop(context);
                      _onNavItemSelected(_navItems.indexWhere((item) => item.type == NavItemType.settings));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDefaultList(String name) {
    final defaultNames = ['My Day', 'Planned', 'Books', 'Todo', 'My Tasks', 'Tasks', 'Important', 'All', 'Completed'];
    return defaultNames.any((defaultName) => name.toLowerCase() == defaultName.toLowerCase());
  }

  Widget _buildDrawerNavItem({
    required NavItem item,
    required bool isDark,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: isSelected ? MSToDoColors.msBlue : (isDark ? MSToDoColors.msTextSecondaryDark : MSToDoColors.msTextSecondary),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          color: isSelected ? MSToDoColors.msBlue : (isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: MSToDoColors.msBlue.withOpacity(0.1),
      onTap: onTap,
    );
  }

  Widget _buildCustomListNavItem(TodoList list, bool isDark) {
    return ListTile(
      leading: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Color(list.color),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        list.name,
        style: TextStyle(
          color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TodoListScreen(list: list),
          ),
        );
      },
    );
  }

  Widget _buildNewListButton(bool isDark) {
    return OutlinedButton.icon(
      onPressed: () {
        _showCreateListDialog();
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('New list'),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
        side: BorderSide(
          color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
        ),
      ),
    );
  }

  void _showCreateListDialog() {
    final nameController = TextEditingController();
    int selectedColor = MSToDoColors.msBlue.toARGB32();

    final colors = [
      0xFF2564CF, // Blue
      0xFF0078D4, // Dark Blue
      0xFF008272, // Teal
      0xFF107C10, // Green
      0xFF5C2D91, // Purple
      0xFFD83B01, // Red
      0xFFCA5010, // Orange
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
        title: const Text('Create new list'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'List name',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: colors.map((color) {
                final isSelected = selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // Handle color selection
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final newList = TodoList(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  color: selectedColor,
                );
                await context.read<DataProvider>().createTodoList(newList);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
