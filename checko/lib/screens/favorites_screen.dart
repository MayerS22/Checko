import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../providers/data_provider.dart';
import '../theme/app_colors.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Todo> _favorites = [];
  List<TodoList> _lists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final dataProvider = context.read<DataProvider>();
    await dataProvider.initialize();

    final favorites = dataProvider.getFavoriteTodos();
    final lists = dataProvider.todoLists;
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _lists = lists;
      _isLoading = false;
    });
  }

  Future<void> _toggleComplete(Todo todo) async {
    setState(() {
      todo.toggleComplete();
    });
    await context.read<DataProvider>().updateTodo(todo);

    if (!mounted) return;
    if (todo.isCompleted) {
      // TODO: Add user stats to DataProvider
      // context.read<DataProvider>().incrementTasksCompleted();
      // context.read<DataProvider>().updateStreak();
    }
  }

  Future<void> _toggleFavorite(Todo todo) async {
    setState(() {
      todo.toggleFavorite();
    });
    await context.read<DataProvider>().updateTodo(todo);
    
    // Remove from list if unfavorited
    if (!todo.isFavorite) {
      setState(() {
        _favorites.removeWhere((t) => t.id == todo.id);
      });
    }
  }

  String _getListName(String listId) {
    final list = _lists.firstWhere(
      (l) => l.id == listId,
      orElse: () => TodoList(id: '', name: 'Unknown'),
    );
    return list.name;
  }

  Color _getListColor(String listId) {
    final list = _lists.firstWhere(
      (l) => l.id == listId,
      orElse: () => TodoList(id: '', name: 'Unknown'),
    );
    return Color(list.color);
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.backgroundColor,
                  AppColors.warning.withValues(alpha: 0.14),
                  AppColors.accent.withValues(alpha: 0.14),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome ${dataProvider.username ?? "User"}',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.surfaceElevatedColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.outlineColor),
                              ),
                              child: Icon(Icons.arrow_back, color: context.textPrimaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.surfaceElevatedColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.outlineColor),
                            ),
                            child: const Icon(Icons.star, color: AppColors.warning, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checko',
                                style: TextStyle(color: context.textMutedColor, fontSize: 14),
                              ),
                              Text(
                                'Favorites',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: context.panelColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                        : _favorites.isEmpty
                            ? _buildEmptyState()
                            : _buildFavoritesList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 74,
            color: context.textMutedColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 14),
          Text(
            'No favorite tasks',
            style: TextStyle(
              fontSize: 18,
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Star tasks to see them here',
            style: TextStyle(
              fontSize: 14,
              color: context.textMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final todo = _favorites[index];
        return _buildFavoriteItem(todo);
      },
    );
  }

  Widget _buildFavoriteItem(Todo todo) {
    final listColor = _getListColor(todo.listId);
    final listName = _getListName(todo.listId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: todo.isCompleted ? AppColors.success : context.outlineColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: GestureDetector(
          onTap: () => _toggleComplete(todo),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: todo.isCompleted ? AppColors.success : AppColors.accent,
                width: 2,
              ),
              color: todo.isCompleted ? AppColors.success : Colors.transparent,
            ),
            child: todo.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            color: todo.isCompleted ? context.textMutedColor : context.textPrimaryColor,
            fontWeight: FontWeight.w600,
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: listColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(listName, style: TextStyle(color: context.textMutedColor, fontSize: 12)),
            if (todo.dueDate != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 14, color: context.textMutedColor),
              const SizedBox(width: 4),
              Text(
                _formatDate(todo.dueDate!),
                style: TextStyle(
                  color: todo.isOverdue ? AppColors.danger : context.textMutedColor,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriorityBadge(todo.priority),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.star,
                color: AppColors.warning,
              ),
              onPressed: () => _toggleFavorite(todo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(Priority priority) {
    Color color;
    String label;
    
    switch (priority) {
      case Priority.high:
        color = AppColors.priorityHigh;
        label = 'High';
        break;
      case Priority.medium:
        color = AppColors.priorityMedium;
        label = 'Med';
        break;
      case Priority.low:
        color = AppColors.priorityLow;
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == tomorrow) return 'Tomorrow';
    return '${date.day}/${date.month}';
  }
}


