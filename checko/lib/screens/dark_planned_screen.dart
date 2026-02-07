import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/todo.dart';
import '../theme/dark_modern_theme.dart';
import '../widgets/glass_task_item.dart';
import '../screens/dark_create_task_screen.dart';

/// Dark & Modern Planned Screen
class DarkPlannedScreen extends StatefulWidget {
  const DarkPlannedScreen({super.key});

  @override
  State<DarkPlannedScreen> createState() => _DarkPlannedScreenState();
}

class _DarkPlannedScreenState extends State<DarkPlannedScreen> {
  List<Todo> _plannedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final dataProvider = context.read<DataProvider>();
    setState(() {
      _plannedTasks = dataProvider.todos
          .where((t) => t.dueDate != null && !t.isCompleted)
          .toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      _isLoading = false;
    });
  }

  Future<void> _toggleTask(String id) async {
    final todo = _plannedTasks.firstWhere((t) => t.id == id);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkModernTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: GlassContainer(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DarkModernTheme.accentBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: DarkModernTheme.accentBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Planned',
                      style: DarkModernTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${_plannedTasks.length}',
                      style: DarkModernTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    // Menu button
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

            // Tasks List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: DarkModernTheme.primary))
                  : _plannedTasks.isEmpty
                      ? _buildEmptyState('No planned tasks')
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
      itemCount: _plannedTasks.length,
      itemBuilder: (context, index) {
        final todo = _plannedTasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassTaskItem(
            todo: todo,
            onToggle: () => _toggleTask(todo.id),
            onTap: () => _editTask(todo),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: DarkModernTheme.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: DarkModernTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
