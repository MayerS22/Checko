import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/todo_list.dart';
import '../models/todo.dart';
import '../theme/dark_modern_theme.dart';
import 'dark_create_list_screen.dart';
import 'dark_create_task_screen.dart';

/// Lists Screen - Shows all custom TodoLists
class DarkListsScreen extends StatelessWidget {
  const DarkListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkModernTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Lists
            Expanded(
              child: Consumer<DataProvider>(
                builder: (context, dataProvider, child) {
                  final lists = dataProvider.todoLists;

                  if (lists.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      return _buildListCard(context, lists[index], index, dataProvider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_lists',
        onPressed: () => _createList(context),
        backgroundColor: DarkModernTheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Menu button for mobile
          if (MediaQuery.of(context).size.width < 600)
            GestureDetector(
              onTap: () => Scaffold.of(context).openEndDrawer(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.menu,
                  color: DarkModernTheme.textSecondary,
                  size: 22,
                ),
              ),
            ),
          if (MediaQuery.of(context).size.width < 600)
            const SizedBox(width: 12),

          Text(
            'Lists',
            style: DarkModernTheme.titleLarge,
          ),
          const Spacer(),
          // List count
          Consumer<DataProvider>(
            builder: (context, dataProvider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DarkModernTheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DarkModernTheme.primary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${dataProvider.todoLists.length}',
                  style: TextStyle(
                    color: DarkModernTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DarkModernTheme.primary.withOpacity(0.3),
                  DarkModernTheme.accentBlue.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.view_list,
              size: 40,
              color: DarkModernTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No lists yet',
            style: DarkModernTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first list to organize tasks',
            style: DarkModernTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createList(context),
            icon: const Icon(Icons.add),
            label: const Text('Create List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DarkModernTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context, TodoList list, int index, DataProvider dataProvider) {
    // Get tasks for this list
    final listTasks = dataProvider.todos.where((t) => t.listId == list.id).toList();
    final incompleteTasks = listTasks.where((t) => !t.isCompleted).length;
    final totalTasks = listTasks.length;
    final allCompleted = totalTasks > 0 && incompleteTasks == 0;

    return GestureDetector(
      onTap: () => _openList(context, list),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DarkModernTheme.surface.withOpacity(0.8),
              DarkModernTheme.surface.withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // List color indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: Color(list.color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),

            // List info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Only show count if there are incomplete tasks
                  if (incompleteTasks > 0)
                    Text(
                      '$incompleteTasks task${incompleteTasks == 1 ? '' : 's'} remaining',
                      style: TextStyle(
                        color: DarkModernTheme.textSecondary,
                        fontSize: 13,
                      ),
                    )
                  else if (totalTasks == 0)
                    Text(
                      'No tasks',
                      style: TextStyle(
                        color: DarkModernTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),

            // Progress indicator or icon
            if (allCompleted)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DarkModernTheme.accentGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: DarkModernTheme.accentGreen,
                  size: 20,
                ),
              )
            else if (totalTasks > 0)
              Text(
                '$incompleteTasks',
                style: TextStyle(
                  color: Color(list.color),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: DarkModernTheme.textTertiary,
                size: 20,
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: Duration(milliseconds: index * 50))
        .slideX(begin: 0.1, end: 0, duration: 300.ms, delay: Duration(milliseconds: index * 50));
  }

  Future<void> _createList(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const DarkCreateListScreen(),
      ),
    );

    if (result == true && context.mounted) {
      // Refresh - DataProvider will notify listeners automatically
      context.read<DataProvider>().loadTodoLists();
    }
  }

  void _openList(BuildContext context, TodoList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ListDetailScreen(list: list),
      ),
    );
  }
}

/// List Detail Screen - Shows tasks in a specific list
class _ListDetailScreen extends StatefulWidget {
  final TodoList list;

  const _ListDetailScreen({required this.list});

  @override
  State<_ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<_ListDetailScreen> {
  bool _showCompleted = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkModernTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with list color
            _buildHeader(context),

            // Tasks
            Expanded(
              child: Consumer<DataProvider>(
                builder: (context, dataProvider, child) {
                  var tasks = dataProvider.todos
                      .where((t) => t.listId == widget.list.id)
                      .toList();

                  // Filter completed tasks if toggle is off
                  if (!_showCompleted) {
                    tasks = tasks.where((t) => !t.isCompleted).toList();
                  }

                  if (tasks.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // Sort: incomplete first, then by creation date
                  tasks.sort((a, b) {
                    if (a.isCompleted != b.isCompleted) {
                      return a.isCompleted ? 1 : -1;
                    }
                    return b.createdAt.compareTo(a.createdAt);
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskItem(context, tasks[index], index, dataProvider);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_list_detail_${widget.list.id}',
        onPressed: () => _addTask(context),
        backgroundColor: Color(widget.list.color),
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(widget.list.color).withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_back,
                color: DarkModernTheme.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // List color
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: Color(widget.list.color),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // List name
          Expanded(
            child: Text(
              widget.list.name,
              style: DarkModernTheme.titleLarge,
            ),
          ),

          // Show completed toggle
          GestureDetector(
            onTap: () => setState(() => _showCompleted = !_showCompleted),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _showCompleted
                    ? Color(widget.list.color).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showCompleted
                      ? Color(widget.list.color).withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showCompleted ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                    color: _showCompleted
                        ? Color(widget.list.color)
                        : DarkModernTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showCompleted ? 'Done' : 'Hide',
                    style: TextStyle(
                      color: _showCompleted
                          ? Color(widget.list.color)
                          : DarkModernTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Color(widget.list.color).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _showCompleted ? 'No tasks' : 'No active tasks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showCompleted ? 'Add tasks to this list' : 'All tasks completed!',
            style: TextStyle(
              color: DarkModernTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          if (!_showCompleted)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: () => setState(() => _showCompleted = true),
                child: Text(
                  'Show completed tasks',
                  style: TextStyle(color: Color(widget.list.color)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Todo todo, int index, DataProvider dataProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleTask(context, todo, dataProvider),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: todo.isCompleted
                      ? DarkModernTheme.accentGreen
                      : DarkModernTheme.textSecondary.withOpacity(0.5),
                  width: 2,
                ),
                color: todo.isCompleted
                    ? DarkModernTheme.accentGreen.withOpacity(0.2)
                    : Colors.transparent,
              ),
              child: todo.isCompleted
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: DarkModernTheme.accentGreen,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Task title
          Expanded(
            child: Text(
              todo.title,
              style: TextStyle(
                color: todo.isCompleted
                    ? DarkModernTheme.textTertiary
                    : Colors.white,
                fontSize: 15,
                decoration: todo.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: DarkModernTheme.textTertiary,
              ),
            ),
          ),
        ],
      ),
    )
        .animate(target: todo.isCompleted ? 1 : 0)
        .scaleXY(
          begin: 1.0,
          end: 0.95,
          duration: 150.ms,
          curve: Curves.easeOut,
        )
        .then()
        .scaleXY(
          begin: 0.95,
          end: 1.0,
          duration: 150.ms,
          curve: Curves.easeOut,
        );
  }

  Future<void> _toggleTask(BuildContext context, Todo todo, DataProvider dataProvider) async {
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    await dataProvider.updateTodo(updated);
  }

  Future<void> _addTask(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DarkCreateTaskScreen(
          defaultList: widget.list,
        ),
      ),
    );

    // The screen will auto-refresh via Provider
  }
}
