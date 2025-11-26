import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../database/firestore_service.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import 'pomodoro_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  List<Todo> _todayTodos = [];
  List<TodoList> _lists = [];
  bool _isLoading = true;
  bool _hideCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final allTodos = await FirestoreService.instance.readAllTodos();
    final lists = await FirestoreService.instance.readAllTodoLists();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get todos due today or overdue
    final todayTodos = allTodos.where((todo) {
      if (todo.dueDate == null) return false;
      final dueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      return dueDate.isBefore(today.add(const Duration(days: 1)));
    }).toList();

    // Sort: incomplete first, then by priority, then by due date
    todayTodos.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.priority.index != b.priority.index) {
        return b.priority.index.compareTo(a.priority.index); // Higher priority first
      }
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      return 0;
    });

    if (!mounted) return;
    setState(() {
      _todayTodos = todayTodos;
      _lists = lists;
      _isLoading = false;
    });
  }

  Future<void> _toggleComplete(Todo todo) async {
    setState(() {
      todo.toggleComplete();
    });
    await FirestoreService.instance.updateTodo(todo);
    
    if (!mounted) return;
    if (todo.isCompleted) {
      context.read<UserProvider>().incrementTasksCompleted();
      context.read<UserProvider>().updateStreak();
    }
  }

  Future<void> _toggleFavorite(Todo todo) async {
    setState(() {
      todo.toggleFavorite();
    });
    await FirestoreService.instance.updateTodo(todo);
  }

  String _getListName(String listId) {
    final list = _lists.firstWhere(
      (l) => l.id == listId,
      orElse: () => TodoList(id: '', name: 'Unknown'),
    );
    return list.name;
  }

  int get _completedCount => _todayTodos.where((t) => t.isCompleted).length;
  int get _pendingCount => _todayTodos.where((t) => !t.isCompleted).length;
  int get _overdueCount => _todayTodos.where((t) => t.isOverdue).length;

  List<Todo> get _visibleTodos {
    if (_hideCompleted) {
      return _todayTodos.where((t) => !t.isCompleted).toList();
    }
    return _todayTodos;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final progress = _todayTodos.isEmpty ? 0.0 : _completedCount / _todayTodos.length;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.backgroundColor,
                  AppColors.accent.withValues(alpha: 0.2),
                  AppColors.accentAlt.withValues(alpha: 0.15),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                          const Spacer(),
                          Text(
                            DateFormat('EEEE, MMM d').format(now),
                            style: TextStyle(
                              color: context.textMutedColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$greeting, ${userProvider.username}!',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getMotivationalMessage(),
                        style: TextStyle(
                          color: context.textMutedColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Progress card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.4),
                              AppColors.accentAlt.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.outlineColor),
                        ),
                        child: Row(
                          children: [
                            // Progress circle
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 8,
                                    backgroundColor: context.surfaceColor.withValues(alpha: 0.5),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                  ),
                                  Text(
                                    '${(progress * 100).round()}%',
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStatRow('✅', 'Completed', _completedCount),
                                  const SizedBox(height: 8),
                                  _buildStatRow('📋', 'Pending', _pendingCount),
                                  if (_overdueCount > 0) ...[
                                    const SizedBox(height: 8),
                                    _buildStatRow('⚠️', 'Overdue', _overdueCount, isWarning: true),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Tasks section
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
                    child: Column(
                      children: [
                        // Filter bar
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                'Today\'s Focus',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(() => _hideCompleted = !_hideCompleted),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _hideCompleted ? AppColors.accent.withValues(alpha: 0.2) : context.surfaceColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _hideCompleted ? AppColors.accent : context.outlineColor,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _hideCompleted ? Icons.visibility_off : Icons.visibility,
                                        size: 16,
                                        color: _hideCompleted ? AppColors.accent : context.textMutedColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Hide done',
                                        style: TextStyle(
                                          color: _hideCompleted ? AppColors.accent : context.textMutedColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tasks list
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                              : _visibleTodos.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: _visibleTodos.length,
                                      itemBuilder: (context, index) {
                                        return _buildTodoItem(_visibleTodos[index]);
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String emoji, String label, int value, {bool isWarning = false}) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: context.textMutedColor, fontSize: 14),
        ),
        const Spacer(),
        Text(
          '$value',
          style: TextStyle(
            color: isWarning ? AppColors.danger : context.textPrimaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            _hideCompleted ? 'All tasks completed!' : 'No tasks for today',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hideCompleted 
                ? 'Great job! Take a well-deserved break.'
                : 'Add tasks with due dates to see them here.',
            style: TextStyle(color: context.textMutedColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItem(Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: todo.isCompleted 
              ? AppColors.success 
              : todo.isOverdue 
                  ? AppColors.danger.withValues(alpha: 0.5)
                  : context.outlineColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: GestureDetector(
              onTap: () => _toggleComplete(todo),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: todo.isCompleted ? AppColors.success : _getPriorityColor(todo.priority),
                    width: 2,
                  ),
                  color: todo.isCompleted ? AppColors.success : Colors.transparent,
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
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
                Text(
                  _getListName(todo.listId),
                  style: TextStyle(color: context.textMutedColor, fontSize: 12),
                ),
                if (todo.isOverdue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (todo.subtasks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.subdirectory_arrow_right, size: 14, color: context.textMutedColor),
                  Text(
                    ' ${todo.completedSubtasksCount}/${todo.subtasks.length}',
                    style: TextStyle(color: context.textMutedColor, fontSize: 12),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPriorityBadge(todo.priority),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    todo.isFavorite ? Icons.star : Icons.star_border,
                    color: todo.isFavorite ? AppColors.warning : context.textMutedColor,
                    size: 22,
                  ),
                  onPressed: () => _toggleFavorite(todo),
                ),
                IconButton(
                  icon: Icon(Icons.timer, color: AppColors.accent, size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PomodoroScreen(linkedTodo: todo),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (todo.note != null && todo.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 60, right: 16, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  todo.note!,
                  style: TextStyle(
                    color: context.textMutedColor,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(Priority priority) {
    final color = _getPriorityColor(priority);
    final label = priority == Priority.high ? '!' : priority == Priority.medium ? '•' : '○';

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return AppColors.priorityHigh;
      case Priority.medium:
        return AppColors.priorityMedium;
      case Priority.low:
        return AppColors.priorityLow;
    }
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getMotivationalMessage() {
    if (_todayTodos.isEmpty) {
      return 'Plan your day and conquer your goals!';
    }
    final progress = _completedCount / _todayTodos.length;
    if (progress >= 1) {
      return 'Amazing! You\'ve crushed all your tasks! 🎉';
    }
    if (progress >= 0.75) {
      return 'Almost there! Just a few more to go!';
    }
    if (progress >= 0.5) {
      return 'Halfway done! Keep up the momentum!';
    }
    if (progress > 0) {
      return 'Great start! Let\'s keep going!';
    }
    return 'Ready to tackle today\'s tasks?';
  }
}

