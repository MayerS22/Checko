import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../providers/data_provider.dart';
import '../theme/ms_todo_colors.dart';
import '../widgets/ms_todo_item.dart';

/// Smart List Screen
///
/// Generic screen for displaying smart lists (Important, Planned, All, Completed)
class SmartListScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Todo> Function() getTodos;

  const SmartListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.getTodos,
  });

  @override
  State<SmartListScreen> createState() => _SmartListScreenState();
}

class _SmartListScreenState extends State<SmartListScreen> {
  late List<Todo> _todos;
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _todos = widget.getTodos();
  }

  @override
  void didUpdateWidget(SmartListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.getTodos != widget.getTodos) {
      setState(() {
        _todos = widget.getTodos();
      });
    }
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    final dataProvider = context.read<DataProvider>();

    // Get the default list for new tasks
    final defaultList = dataProvider.todoLists.firstWhere(
      (l) => l.name == 'My Tasks' || l.name == 'Tasks',
      orElse: () => dataProvider.todoLists.isNotEmpty
          ? dataProvider.todoLists.first
          : TodoList(id: 'default', name: 'Tasks'),
    );

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      listId: defaultList.id,
      title: _taskController.text.trim(),
      order: _todos.length,
    );

    await dataProvider.createTodo(newTodo);
    _taskController.clear();
    _focusNode.unfocus();

    setState(() {
      _todos = widget.getTodos();
    });
  }

  Future<void> _toggleTask(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.toggleComplete();
    await context.read<DataProvider>().updateTodo(todo);
    setState(() {
      _todos = widget.getTodos();
    });
  }

  Future<void> _deleteTask(String id) async {
    await context.read<DataProvider>().deleteTodo(id);
    setState(() {
      _todos = widget.getTodos();
    });
  }

  Future<void> _toggleFavorite(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.toggleFavorite();
    await context.read<DataProvider>().updateTodo(todo);
    setState(() {
      _todos = widget.getTodos();
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final dataProvider = context.watch<DataProvider>();

    // Refresh todos when data provider changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final newTodos = widget.getTodos();
        if (newTodos.length != _todos.length) {
          setState(() {
            _todos = newTodos;
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: isDark ? MSToDoColors.msBackgroundDark : MSToDoColors.msBackground,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 65, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_todos.length} task${_todos.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: MSToDoColors.msTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Task input (not for Completed list)
          if (widget.title != 'Completed')
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.add, color: MSToDoColors.msBlue),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _taskController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Add a task',
                        hintStyle: TextStyle(color: MSToDoColors.msTextSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _addTask(),
                    ),
                  ),
                ],
              ),
            ),

          // Tasks list
          Expanded(
            child: _todos.isEmpty
                ? _buildEmptyState(isDark)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _todos.map((todo) => MSTodoItem(
                      todo: todo,
                      onToggle: () => _toggleTask(todo.id),
                      onDelete: () => _deleteTask(todo.id),
                      onFavorite: () => _toggleFavorite(todo.id),
                      isDark: isDark,
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.title == 'Completed' ? Icons.check_circle_outline : Icons.list_alt,
            size: 64,
            color: MSToDoColors.msTextSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title == 'Completed'
                ? 'No completed tasks yet'
                : 'No tasks here',
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.title == 'Completed'
                ? 'Completed tasks will appear here'
                : 'Tasks will appear here when you add them',
            style: TextStyle(
              color: MSToDoColors.msTextSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
