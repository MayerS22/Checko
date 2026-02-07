import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../providers/data_provider.dart';
import '../theme/dark_modern_theme.dart';
import '../widgets/glass_task_item.dart';
import '../screens/dark_create_task_screen.dart';

/// Dark & Modern My Day Screen
///
/// Features:
/// - Glassmorphism effects
/// - Compact layout
/// - Quick task entry
class DarkMyDayScreen extends StatefulWidget {
  const DarkMyDayScreen({super.key});

  @override
  State<DarkMyDayScreen> createState() => _DarkMyDayScreenState();
}

class _DarkMyDayScreenState extends State<DarkMyDayScreen> {
  final TextEditingController _taskController = TextEditingController();
  List<Todo> _myDayTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final dataProvider = context.read<DataProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final myDayList = dataProvider.todoLists.firstWhere(
      (l) => l.name == 'My Day',
      orElse: () => TodoList(id: '', name: ''),
    );

    if (myDayList.id.isEmpty) {
      setState(() {
        _myDayTasks = [];
        _isLoading = false;
      });
      return;
    }

    final tasksForMyDay = dataProvider.todos.where((todo) {
      if (todo.listId == myDayList.id) return true;
      if (todo.dueDate != null && !todo.isCompleted) {
        final dueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
        return dueDate.isAtSameMomentAs(today);
      }
      return false;
    }).toList();

    setState(() {
      _myDayTasks = tasksForMyDay.toList();
      _isLoading = false;
    });
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    final dataProvider = context.read<DataProvider>();
    final myDayList = dataProvider.todoLists.firstWhere(
      (l) => l.name == 'My Day',
      orElse: () => dataProvider.todoLists.isNotEmpty
          ? dataProvider.todoLists.first
          : TodoList(id: 'default', name: 'My Day'),
    );

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      listId: myDayList.id,
      title: _taskController.text.trim(),
      dueDate: DateTime.now(),
      order: _myDayTasks.length,
    );

    await dataProvider.createTodo(newTodo);
    _taskController.clear();
    await _loadTasks();
  }

  Future<void> _toggleTask(String id) async {
    final todo = _myDayTasks.firstWhere((t) => t.id == id);
    todo.toggleComplete();
    await context.read<DataProvider>().updateTodo(todo);
    await _loadTasks();
  }

  Future<void> _editTask(Todo todo) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DarkCreateTaskScreen(todo: todo),
      ),
    );

    if (result == true) {
      await _loadTasks();
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: DarkModernTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Compact Header with glass effect
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DarkModernTheme.accentYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: DarkModernTheme.accentYellow,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Day',
                            style: DarkModernTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            today,
                            style: DarkModernTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    // Menu button to open drawer
                    GestureDetector(
                      onTap: () => Scaffold.of(context).openEndDrawer(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.menu,
                          color: DarkModernTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Quick Add Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassContainer(
                padding: EdgeInsets.zero,
                margin: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _taskController,
                  style: DarkModernTheme.bodyLarge,
                  onSubmitted: (_) => _addTask(),
                  decoration: InputDecoration(
                    hintText: 'Add a task for today...',
                    hintStyle: TextStyle(color: DarkModernTheme.textSecondary, fontSize: 15),
                    prefixIcon: const Icon(Icons.add, size: 20, color: DarkModernTheme.primary),
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: DarkModernTheme.textTertiary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Tasks List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: DarkModernTheme.primary))
                  : _myDayTasks.isEmpty
                      ? _buildEmptyState()
                      : _buildTasksList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _myDayTasks.length,
      itemBuilder: (context, index) {
        final todo = _myDayTasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassTaskItem(
            todo: todo,
            onToggle: () => _toggleTask(todo.id),
            onTap: () => _editTask(todo),
            isDark: true,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 48,
            color: DarkModernTheme.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No tasks for today',
            style: DarkModernTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Add tasks above or plan your day',
            style: DarkModernTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
