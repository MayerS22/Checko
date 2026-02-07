import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/todo.dart';
import '../theme/dark_modern_theme.dart';
import '../widgets/glass_task_item.dart';
import '../screens/dark_create_task_screen.dart';

/// Dark & Modern Important Screen
class DarkImportantScreen extends StatefulWidget {
  const DarkImportantScreen({super.key});

  @override
  State<DarkImportantScreen> createState() => _DarkImportantScreenState();
}

class _DarkImportantScreenState extends State<DarkImportantScreen> {
  List<Todo> _importantTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final dataProvider = context.read<DataProvider>();
    setState(() {
      _importantTasks = dataProvider.todos.where((t) => t.isFavorite && !t.isCompleted).toList();
      _isLoading = false;
    });
  }

  Future<void> _toggleTask(String id) async {
    final todo = _importantTasks.firstWhere((t) => t.id == id);
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
                        color: DarkModernTheme.accentYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.star_border_rounded,
                        color: DarkModernTheme.accentYellow,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Important',
                      style: DarkModernTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${_importantTasks.length}',
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
                  : _importantTasks.isEmpty
                      ? _buildEmptyState('No important tasks yet')
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
      itemCount: _importantTasks.length,
      itemBuilder: (context, index) {
        final todo = _importantTasks[index];
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
            Icons.star_border_rounded,
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
