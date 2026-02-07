import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../providers/data_provider.dart';
import '../theme/ms_todo_colors.dart';
import '../widgets/ms_todo_item.dart';

/// Todo List Screen
///
/// Displays tasks for a specific user-created list
class TodoListScreen extends StatefulWidget {
  final TodoList list;

  const TodoListScreen({
    super.key,
    required this.list,
  });

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late List<Todo> _todos;
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final dataProvider = context.read<DataProvider>();
    setState(() {
      _todos = dataProvider.getTodosForList(widget.list.id);
    });
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      listId: widget.list.id,
      title: _taskController.text.trim(),
      order: _todos.length,
    );

    await context.read<DataProvider>().createTodo(newTodo);
    _taskController.clear();
    _focusNode.unfocus();
    await _loadTodos();
  }

  Future<void> _toggleTask(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.toggleComplete();
    await context.read<DataProvider>().updateTodo(todo);
    await _loadTodos();
  }

  Future<void> _deleteTask(String id) async {
    await context.read<DataProvider>().deleteTodo(id);
    await _loadTodos();
  }

  Future<void> _toggleFavorite(String id) async {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.toggleFavorite();
    await context.read<DataProvider>().updateTodo(todo);
    await _loadTodos();
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
    final listColor = Color(widget.list.color);

    return Scaffold(
      backgroundColor: isDark ? MSToDoColors.msBackgroundDark : MSToDoColors.msBackground,
      body: Column(
        children: [
          // Header with list color
          Container(
            padding: const EdgeInsets.fromLTRB(16, 65, 16, 8),
            decoration: BoxDecoration(
              color: listColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: listColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.list.name,
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

          // Task input
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                ? _buildEmptyState(isDark, listColor)
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

  Widget _buildEmptyState(bool isDark, Color listColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 64,
            color: MSToDoColors.msTextSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first task to ${widget.list.name}',
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
