import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/subtask.dart';
import '../models/tag.dart';
import '../models/recurrence.dart';
import '../database/firestore_service.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import 'pomodoro_screen.dart';

enum _TodoFilter { all, active, done }

class TodoScreen extends StatefulWidget {
  final TodoList list;
  final List<Todo> todos;
  final Function(List<Todo>) onTodosChanged;

  const TodoScreen({
    super.key,
    required this.list,
    required this.todos,
    required this.onTodosChanged,
  });

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late List<Todo> _todos;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  _TodoFilter _filter = _TodoFilter.all;

  @override
  void initState() {
    super.initState();
    _todos = List.from(widget.todos);
    // Sort by order
    _todos.sort((a, b) => a.order.compareTo(b.order));
  }

  List<Todo> get _visibleTodos {
    switch (_filter) {
      case _TodoFilter.active:
        return _todos.where((todo) => !todo.isCompleted).toList();
      case _TodoFilter.done:
        return _todos.where((todo) => todo.isCompleted).toList();
      case _TodoFilter.all:
        return _todos;
    }
  }

  int get _completedCount => _todos.where((todo) => todo.isCompleted).length;

  Future<void> _addTodo() async {
    if (_textController.text.trim().isEmpty) return;

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      listId: widget.list.id,
      title: _textController.text.trim(),
      dueDate: widget.list.name == 'My Day'
          ? DateTime.now()
          : null,
      order: _todos.length,
    );

    // Persist first to get the Firestore-generated ID so later edits/deletes work
    final createdTodo = await FirestoreService.instance.createTodo(newTodo);

    setState(() {
      _todos.add(createdTodo);
      _textController.clear();
    });
    widget.onTodosChanged(_todos);
    _focusNode.unfocus();
  }

  Future<void> _deleteTodo(String id) async {
    await FirestoreService.instance.deleteTodo(id);

    setState(() {
      _todos.removeWhere((todo) => todo.id == id);
    });
    widget.onTodosChanged(_todos);
  }

  Future<void> _toggleTodo(String id) async {
    final todo = _todos.firstWhere((todo) => todo.id == id);
    final wasCompleted = todo.isCompleted;
    
    setState(() {
      todo.toggleComplete();
    });

    await FirestoreService.instance.updateTodo(todo);
    widget.onTodosChanged(_todos);

    // Update user stats
    if (!wasCompleted && todo.isCompleted) {
      if (mounted) {
        context.read<UserProvider>().incrementTasksCompleted();
        context.read<UserProvider>().updateStreak();
      }
      
      // Handle recurring tasks
      if (todo.recurrence.isRecurring) {
        final nextDate = todo.recurrence.getNextOccurrence(todo.dueDate ?? DateTime.now());
        if (nextDate != null) {
          final newTodo = todo.copyWith(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            dueDate: nextDate,
            isCompleted: false,
            completedAt: null,
            order: _todos.length,
          );
          final createdTodo = await FirestoreService.instance.createTodo(newTodo);
          setState(() {
            _todos.add(createdTodo);
          });
          widget.onTodosChanged(_todos);
        }
      }
    }
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() {
      final todo = _todos.firstWhere((todo) => todo.id == id);
      todo.toggleFavorite();
    });

    final todo = _todos.firstWhere((todo) => todo.id == id);
    await FirestoreService.instance.updateTodo(todo);
    widget.onTodosChanged(_todos);
  }

  void _setFilter(_TodoFilter filter) {
    setState(() {
      _filter = filter;
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final visibleTodos = _visibleTodos;
    final item = visibleTodos[oldIndex];
    
    setState(() {
      visibleTodos.removeAt(oldIndex);
      visibleTodos.insert(newIndex, item);
      
      // Update order for all items
      for (int i = 0; i < visibleTodos.length; i++) {
        visibleTodos[i].order = i;
      }
    });

    // Save to Firestore
    for (var todo in visibleTodos) {
      await FirestoreService.instance.updateTodoOrder(todo.id, todo.order);
    }
    
    widget.onTodosChanged(_todos);
  }

  Future<void> _showTodoDetails(Todo todo) async {
    final result = await showModalBottomSheet<Todo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TodoDetailSheet(
        todo: todo,
        onUpdate: (updatedTodo) async {
          await FirestoreService.instance.updateTodo(updatedTodo);
          setState(() {
            final index = _todos.indexWhere((t) => t.id == updatedTodo.id);
            if (index != -1) {
              _todos[index] = updatedTodo;
            }
          });
          widget.onTodosChanged(_todos);
        },
      ),
    );
    
    if (result != null) {
      await FirestoreService.instance.updateTodo(result);
      setState(() {
        final index = _todos.indexWhere((t) => t.id == result.id);
        if (index != -1) {
          _todos[index] = result;
        }
      });
      widget.onTodosChanged(_todos);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final completedCount = _completedCount;
    final totalCount = _todos.length;
    final visibleTodos = _visibleTodos;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  context.backgroundColor,
                  AppColors.accent.withValues(alpha: 0.14),
                  AppColors.accentAlt.withValues(alpha: 0.14),
                  context.panelColor,
                ],
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            left: -20,
            top: 40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentAlt.withValues(alpha: 0.1),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome ${userProvider.username}',
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              IconButton(
                                splashRadius: 24,
                                onPressed: () => Navigator.pop(context),
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: context.surfaceElevatedColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.outlineColor),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: context.textPrimaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(widget.list.color).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: context.outlineColor),
                                ),
                                child: Icon(
                                  Icons.task_alt,
                                  color: Color(widget.list.color),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Checko',
                                      style: TextStyle(
                                        color: context.textMutedColor,
                                        fontSize: 14,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    Text(
                                      widget.list.name,
                                      style: TextStyle(
                                        color: context.textPrimaryColor,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                splashRadius: 24,
                                onPressed: _focusNode.requestFocus,
                                icon: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.surfaceElevatedColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.outlineColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 72,
                                  width: 72,
                                  child: CircularProgressIndicator(
                                    value: totalCount == 0 ? 0 : completedCount / totalCount,
                                    strokeWidth: 8,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                    backgroundColor: context.surfaceColor,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      totalCount == 0
                                          ? '0%'
                                          : '${((completedCount / totalCount) * 100).round()}%',
                                      style: TextStyle(
                                        color: context.textPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      'done',
                                      style: TextStyle(
                                        color: context.textMutedColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    totalCount == 0
                                        ? 'Nothing scheduled yet'
                                        : '$completedCount of $totalCount completed',
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    totalCount == 0
                                        ? 'Add your first task to get momentum.'
                                        : 'Stay consistent and clear the deck.',
                                    style: TextStyle(
                                      color: context.textMutedColor,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (totalCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: LinearProgressIndicator(
                                          value: completedCount / totalCount,
                                          backgroundColor: context.surfaceColor,
                                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _TodoFilter.values
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        filter == _TodoFilter.all
                                            ? Icons.layers
                                            : filter == _TodoFilter.active
                                                ? Icons.radio_button_unchecked
                                                : Icons.task_alt,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        filter == _TodoFilter.all
                                            ? 'All'
                                            : filter == _TodoFilter.active
                                                ? 'Active'
                                                : 'Done',
                                      ),
                                    ],
                                  ),
                                  selected: _filter == filter,
                                  onSelected: (_) => _setFilter(filter),
                                  selectedColor: AppColors.accent,
                                  labelStyle: TextStyle(
                                    color: _filter == filter ? Colors.white : context.textMutedColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  backgroundColor: context.surfaceColor,
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: _filter == filter ? AppColors.accent : context.outlineColor,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            )
                            .toList(),
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
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.surfaceColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(color: context.outlineColor),
                            ),
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              style: TextStyle(color: context.textPrimaryColor),
                              decoration: InputDecoration(
                                hintText: 'Add a task with intent...',
                                hintStyle: TextStyle(color: context.textMutedColor, fontSize: 15),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                prefixIcon: Icon(Icons.edit_outlined, color: context.textMutedColor),
                                suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 4,
                                      backgroundColor: AppColors.accent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    onPressed: _addTodo,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 18, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _addTodo(),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: visibleTodos.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.incomplete_circle_outlined,
                                          size: 74,
                                          color: context.textMutedColor.withValues(alpha: 0.6),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          _filter == _TodoFilter.done
                                              ? 'Nothing completed yet'
                                              : 'No tasks to show',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: context.textPrimaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _filter == _TodoFilter.done
                                              ? 'Finish something to see it here.'
                                              : 'Add a task or change the filter.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: context.textMutedColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ReorderableListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                                    itemCount: visibleTodos.length,
                                    onReorder: _onReorder,
                                    proxyDecorator: (child, index, animation) {
                                      return AnimatedBuilder(
                                        animation: animation,
                                        builder: (context, child) {
                                          return Material(
                                            elevation: 8,
                                            color: Colors.transparent,
                                            shadowColor: AppColors.accent.withValues(alpha: 0.3),
                                            child: child,
                                          );
                                        },
                                        child: child,
                                      );
                                    },
                                    itemBuilder: (context, index) {
                                      final todo = visibleTodos[index];
                                      return _TodoItem(
                                        key: ValueKey(todo.id),
                                        todo: todo,
                                        onToggle: () => _toggleTodo(todo.id),
                                        onDelete: () => _deleteTodo(todo.id),
                                        onFavorite: () => _toggleFavorite(todo.id),
                                        onTap: () => _showTodoDetails(todo),
                                        onStartPomodoro: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PomodoroScreen(linkedTodo: todo),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
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
}

class _TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final VoidCallback onTap;
  final VoidCallback onStartPomodoro;

  const _TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onFavorite,
    required this.onTap,
    required this.onStartPomodoro,
  });

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

  @override
  Widget build(BuildContext context) {
    final hasSubtasks = todo.subtasks.isNotEmpty;
    final hasTags = todo.tags.isNotEmpty;
    final priorityColor = _getPriorityColor(todo.priority);

    return Dismissible(
      key: Key('dismiss-${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.danger.withValues(alpha: 0.7), AppColors.danger],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: todo.isCompleted
                  ? [AppColors.success.withValues(alpha: 0.24), AppColors.success.withValues(alpha: 0.12)]
                  : [context.surfaceColor, context.surfaceElevatedColor],
            ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    // Priority indicator + checkbox
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: todo.isCompleted ? AppColors.success : priorityColor,
                            width: 2,
                          ),
                          color: todo.isCompleted ? AppColors.success : Colors.transparent,
                        ),
                        child: todo.isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  todo.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: todo.isCompleted ? context.textMutedColor : context.textPrimaryColor,
                                    decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              // Priority badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  todo.priority == Priority.high
                                      ? 'High'
                                      : todo.priority == Priority.medium
                                          ? 'Med'
                                          : 'Low',
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (hasSubtasks) ...[
                                Icon(Icons.subdirectory_arrow_right, size: 14, color: context.textMutedColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${todo.completedSubtasksCount}/${todo.subtasks.length}',
                                  style: TextStyle(fontSize: 12, color: context.textMutedColor),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (todo.dueDate != null) ...[
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: todo.isOverdue ? AppColors.danger : context.textMutedColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(todo.dueDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: todo.isOverdue ? AppColors.danger : context.textMutedColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (todo.recurrence.isRecurring) ...[
                                Icon(Icons.repeat, size: 14, color: AppColors.accent),
                                const SizedBox(width: 4),
                              ],
                              if (todo.pomodoroSessions > 0) ...[
                                const Text('🍅', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 2),
                                Text(
                                  '${todo.pomodoroSessions}',
                                  style: TextStyle(fontSize: 12, color: context.textMutedColor),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    IconButton(
                      splashRadius: 20,
                      icon: Icon(
                        todo.isFavorite ? Icons.star : Icons.star_border,
                        color: todo.isFavorite ? AppColors.warning : context.textMutedColor,
                        size: 22,
                      ),
                      onPressed: onFavorite,
                    ),
                    IconButton(
                      splashRadius: 20,
                      icon: const Icon(Icons.timer, color: AppColors.accent, size: 22),
                      onPressed: onStartPomodoro,
                    ),
                  ],
                ),
              ),
              
              // Tags row
              if (hasTags)
                Padding(
                  padding: const EdgeInsets.only(left: 58, right: 14, bottom: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: todo.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(tag.color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(tag.color).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '#${tag.name}',
                          style: TextStyle(
                            color: Color(tag.color),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              // Note preview
              if (todo.note != null && todo.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 58, right: 14, bottom: 12),
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
            ],
          ),
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
    if (dateOnly.isBefore(today)) return 'Overdue';
    return DateFormat('MMM d').format(date);
  }
}

// Todo Detail Bottom Sheet
class _TodoDetailSheet extends StatefulWidget {
  final Todo todo;
  final Function(Todo) onUpdate;

  const _TodoDetailSheet({required this.todo, required this.onUpdate});

  @override
  State<_TodoDetailSheet> createState() => _TodoDetailSheetState();
}

class _TodoDetailSheetState extends State<_TodoDetailSheet> {
  late Todo _todo;
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  late TextEditingController _subtaskController;

  @override
  void initState() {
    super.initState();
    _todo = widget.todo;
    _titleController = TextEditingController(text: _todo.title);
    _noteController = TextEditingController(text: _todo.note ?? '');
    _subtaskController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _updateTodo() {
    _todo = _todo.copyWith(
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    widget.onUpdate(_todo);
  }

  void _addSubtask() {
    if (_subtaskController.text.trim().isEmpty) return;
    
    final subtask = SubTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _subtaskController.text.trim(),
    );
    
    setState(() {
      _todo.addSubtask(subtask);
      _subtaskController.clear();
    });
    widget.onUpdate(_todo);
  }

  void _toggleSubtask(String id) {
    setState(() {
      final subtask = _todo.subtasks.firstWhere((s) => s.id == id);
      subtask.toggleComplete();
    });
    widget.onUpdate(_todo);
  }

  void _deleteSubtask(String id) {
    setState(() {
      _todo.removeSubtask(id);
    });
    widget.onUpdate(_todo);
  }

  void _setPriority(Priority priority) {
    setState(() {
      _todo = _todo.copyWith(priority: priority);
    });
    widget.onUpdate(_todo);
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _todo.dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _todo = _todo.copyWith(dueDate: date);
      });
      widget.onUpdate(_todo);
    }
  }

  void _setRecurrence(RecurrenceType type) {
    setState(() {
      _todo = _todo.copyWith(
        recurrence: RecurrenceRule(type: type),
      );
    });
    widget.onUpdate(_todo);
    Navigator.pop(context);
  }

  void _toggleTag(Tag tag) {
    setState(() {
      if (_todo.tags.any((t) => t.id == tag.id)) {
        _todo.removeTag(tag.id);
      } else {
        _todo.addTag(tag);
      }
    });
    widget.onUpdate(_todo);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.panelColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.outlineColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      hintStyle: TextStyle(color: context.textMutedColor),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => _updateTodo(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Priority selector
                  Text('Priority', style: TextStyle(color: context.textMutedColor, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: Priority.values.map((priority) {
                      final isSelected = _todo.priority == priority;
                      final color = priority == Priority.high
                          ? AppColors.priorityHigh
                          : priority == Priority.medium
                              ? AppColors.priorityMedium
                              : AppColors.priorityLow;
                      final label = priority == Priority.high
                          ? 'High'
                          : priority == Priority.medium
                              ? 'Medium'
                              : 'Low';
                      
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _setPriority(priority),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withValues(alpha: 0.2) : context.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? color : context.outlineColor,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected ? color : context.textMutedColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Due date
                  Text('Due Date', style: TextStyle(color: context.textMutedColor, fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDueDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.outlineColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.accent),
                          const SizedBox(width: 12),
                          Text(
                            _todo.dueDate != null
                                ? DateFormat('EEEE, MMM d, yyyy').format(_todo.dueDate!)
                                : 'Set due date',
                            style: TextStyle(color: context.textPrimaryColor),
                          ),
                          const Spacer(),
                          if (_todo.dueDate != null)
                            IconButton(
                              icon: Icon(Icons.clear, color: context.textMutedColor),
                              onPressed: () {
                                setState(() {
                                  _todo = _todo.copyWith(dueDate: null);
                                });
                                widget.onUpdate(_todo);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Recurrence
                  Text('Repeat', style: TextStyle(color: context.textMutedColor, fontSize: 14)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: context.panelColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: RecurrenceType.values.map((type) {
                            final rule = RecurrenceRule(type: type);
                            return ListTile(
                              leading: Icon(
                                type == RecurrenceType.none ? Icons.close : Icons.repeat,
                                color: _todo.recurrence.type == type ? AppColors.accent : context.textMutedColor,
                              ),
                              title: Text(
                                rule.displayText,
                                style: TextStyle(
                                  color: _todo.recurrence.type == type ? AppColors.accent : context.textPrimaryColor,
                                ),
                              ),
                              trailing: _todo.recurrence.type == type
                                  ? const Icon(Icons.check, color: AppColors.accent)
                                  : null,
                              onTap: () => _setRecurrence(type),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.outlineColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.repeat, color: AppColors.accent),
                          const SizedBox(width: 12),
                          Text(
                            _todo.recurrence.displayText,
                            style: TextStyle(color: context.textPrimaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Tags
                  Text('Tags', style: TextStyle(color: context.textMutedColor, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Tag.defaultTags.map((tag) {
                      final isSelected = _todo.tags.any((t) => t.id == tag.id);
                      return GestureDetector(
                        onTap: () => _toggleTag(tag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(tag.color).withValues(alpha: 0.2)
                                : context.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Color(tag.color) : context.outlineColor,
                            ),
                          ),
                          child: Text(
                            '#${tag.name}',
                            style: TextStyle(
                              color: isSelected ? Color(tag.color) : context.textMutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Notes
                  Text('Notes', style: TextStyle(color: context.textMutedColor, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.outlineColor),
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 4,
                      style: TextStyle(color: context.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: 'Add notes...',
                        hintStyle: TextStyle(color: context.textMutedColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onChanged: (_) => _updateTodo(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Subtasks
                  Row(
                    children: [
                      Text('Subtasks', style: TextStyle(color: context.textMutedColor, fontSize: 14)),
                      const Spacer(),
                      Text(
                        '${_todo.completedSubtasksCount}/${_todo.subtasks.length}',
                        style: TextStyle(color: context.textMutedColor, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Add subtask input
                  Container(
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.outlineColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subtaskController,
                            style: TextStyle(color: context.textPrimaryColor),
                            decoration: InputDecoration(
                              hintText: 'Add subtask...',
                              hintStyle: TextStyle(color: context.textMutedColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            onSubmitted: (_) => _addSubtask(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: AppColors.accent),
                          onPressed: _addSubtask,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtask list
                  ...  _todo.subtasks.map((subtask) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.outlineColor),
                      ),
                      child: ListTile(
                        leading: GestureDetector(
                          onTap: () => _toggleSubtask(subtask.id),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: subtask.isCompleted ? AppColors.success : context.textMutedColor,
                              ),
                              color: subtask.isCompleted ? AppColors.success : Colors.transparent,
                            ),
                            child: subtask.isCompleted
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                        title: Text(
                          subtask.title,
                          style: TextStyle(
                            color: subtask.isCompleted ? context.textMutedColor : context.textPrimaryColor,
                            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close, size: 18, color: context.textMutedColor),
                          onPressed: () => _deleteSubtask(subtask.id),
                        ),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
