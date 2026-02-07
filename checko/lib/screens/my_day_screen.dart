import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../providers/data_provider.dart';
import '../theme/ms_todo_colors.dart';
import '../widgets/ms_todo_item.dart';

/// My Day Screen
///
/// Shows tasks for today with suggestions from other lists
/// Resets daily at midnight
class MyDayScreen extends StatefulWidget {
  const MyDayScreen({super.key});

  @override
  State<MyDayScreen> createState() => _MyDayScreenState();
}

class _MyDayScreenState extends State<MyDayScreen> {
  late List<Todo> _myDayTasks;
  late List<Todo> _suggestedTasks;
  bool _showSuggestions = true;
  final TextEditingController _taskController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _myDayTasks = [];
    _suggestedTasks = [];
    _loadMyDayTasks();
  }

  Future<void> _loadMyDayTasks() async {
    final dataProvider = context.read<DataProvider>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get tasks due today or explicitly in My Day
    final myDayList = dataProvider.todoLists.firstWhere(
      (l) => l.name == 'My Day',
      orElse: () => TodoList(id: '', name: ''),
    );

    if (myDayList.id.isEmpty) {
      setState(() {
        _myDayTasks = [];
        _suggestedTasks = [];
      });
      return;
    }

    final tasksForMyDay = dataProvider.todos.where((todo) {
      // Show if explicitly in My Day list
      if (todo.listId == myDayList.id) return true;

      // Show if due today and not completed
      if (todo.dueDate != null && !todo.isCompleted) {
        final dueDate = DateTime(
          todo.dueDate!.year,
          todo.dueDate!.month,
          todo.dueDate!.day,
        );
        return dueDate.isAtSameMomentAs(today);
      }

      return false;
    }).toList();

    // Generate suggestions
    final suggestions = _generateSuggestions(dataProvider.todos, today);

    setState(() {
      _myDayTasks = tasksForMyDay.toList();
      _suggestedTasks = suggestions;
    });
  }

  List<Todo> _generateSuggestions(List<Todo> allTodos, DateTime today) {
    // Suggest overdue tasks
    final overdue = allTodos.where((t) =>
        !t.isCompleted &&
        t.dueDate != null &&
        t.dueDate!.isBefore(today) &&
        t.dueDate!.day != today.day
    ).toList();

    // Suggest high priority tasks from last 2 days
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final recentHighPriority = allTodos.where((t) =>
        !t.isCompleted &&
        t.priority == Priority.high &&
        t.createdAt.isAfter(twoDaysAgo)
    ).toList();

    // Combine and limit
    final suggestions = [
      ...overdue.take(3),
      ...recentHighPriority.take(3),
    ].toSet().toList();

    return suggestions.take(5).toList();
  }

  Future<void> _addTask() async {
    if (_taskController.text.trim().isEmpty) return;

    final dataProvider = context.read<DataProvider>();
    final myDayList = dataProvider.todoLists.firstWhere(
      (l) => l.name == 'My Day',
      orElse: () => TodoList(id: '', name: ''),
    );

    if (myDayList.id.isEmpty) return;

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      listId: myDayList.id,
      title: _taskController.text.trim(),
      dueDate: DateTime.now(),
      order: _myDayTasks.length,
    );

    await dataProvider.createTodo(newTodo);
    _taskController.clear();
    _focusNode.unfocus();
    await _loadMyDayTasks();
  }

  Future<void> _addToMyDay(Todo todo) async {
    final dataProvider = context.read<DataProvider>();
    final myDayList = dataProvider.todoLists.firstWhere(
      (l) => l.name == 'My Day',
      orElse: () => TodoList(id: '', name: ''),
    );

    if (myDayList.id.isEmpty) return;

    // Create a copy in My Day
    final myDayTodo = todo.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      listId: myDayList.id,
      dueDate: DateTime.now(),
    );

    await dataProvider.createTodo(myDayTodo);
    await _loadMyDayTasks();
  }

  Future<void> _toggleTask(String id) async {
    final todo = _myDayTasks.firstWhere((t) => t.id == id);
    todo.toggleComplete();
    await context.read<DataProvider>().updateTodo(todo);
    await _loadMyDayTasks();
  }

  Future<void> _deleteTask(String id) async {
    await context.read<DataProvider>().deleteTodo(id);
    await _loadMyDayTasks();
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
    final today = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: isDark ? MSToDoColors.msBackgroundDark : MSToDoColors.msBackground,
      body: Column(
        children: [
          // Compact header with gradient
          Container(
            padding: const EdgeInsets.fromLTRB(16, 65, 16, 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A90E2),
                  Color(0xFF2564CF),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.wb_sunny,
                    color: Colors.white,
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
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        today,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Task input - moved closer to header
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
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.add, color: MSToDoColors.msBlue, size: 20),
                ),
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: 'Add a task',
                      hintStyle: TextStyle(color: MSToDoColors.msTextSecondary, fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 15),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
              ],
            ),
          ),

          // Tasks list or suggestions
          Expanded(
            child: _myDayTasks.isEmpty && _suggestedTasks.isEmpty
                ? _buildEmptyState(isDark)
                : _myDayTasks.isEmpty
                    ? _buildSuggestions(isDark)
                    : _buildTasksList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Text(
          '${_myDayTasks.length} task${_myDayTasks.length == 1 ? '' : 's'}',
          style: TextStyle(
            color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ..._myDayTasks.map((todo) => MSTodoItem(
          todo: todo,
          onToggle: () => _toggleTask(todo.id),
          onDelete: () => _deleteTask(todo.id),
          isDark: isDark,
        )),
      ],
    );
  }

  Widget _buildSuggestions(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? MSToDoColors.msSurfaceDark : MSToDoColors.msSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? MSToDoColors.msBorderDark : MSToDoColors.msBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggestions',
                style: TextStyle(
                  color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showSuggestions = false;
                  });
                },
                child: const Text('Clear', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._suggestedTasks.take(3).map((todo) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: MSToDoColors.msBlue, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        todo.title,
                        style: TextStyle(
                          color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _addToMyDay(todo),
                      child: const Text('Add', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wb_sunny_outlined,
            size: 48,
            color: MSToDoColors.msTextSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'My Day is empty',
            style: TextStyle(
              color: isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a task to get started',
            style: TextStyle(
              color: MSToDoColors.msTextSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
