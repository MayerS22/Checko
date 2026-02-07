import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/subtask.dart';
import '../providers/data_provider.dart';
import '../theme/dark_modern_theme.dart';

/// Create/Edit Task Screen with Subtasks
class DarkCreateTaskScreen extends StatefulWidget {
  final Todo? todo; // null = creating new, otherwise editing
  final TodoList? defaultList;

  const DarkCreateTaskScreen({
    super.key,
    this.todo,
    this.defaultList,
  });

  @override
  State<DarkCreateTaskScreen> createState() => _DarkCreateTaskScreenState();
}

class _DarkCreateTaskScreenState extends State<DarkCreateTaskScreen> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _subtaskController = TextEditingController();
  final _focusNode = FocusNode();

  DateTime? _dueDate;
  late Priority _priority;
  TodoList? _selectedList;
  late List<SubTask> _subtasks;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      // Editing existing task
      _titleController.text = widget.todo!.title;
      _noteController.text = widget.todo!.note ?? '';
      _dueDate = widget.todo!.dueDate;
      _priority = widget.todo!.priority;
      _subtasks = List.from(widget.todo!.subtasks);
    } else {
      // Creating new task
      _dueDate = null;
      _priority = Priority.medium;
      _subtasks = [];
    }
    _selectedList = widget.defaultList;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _subtaskController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final lists = dataProvider.todoLists;

    return Scaffold(
      backgroundColor: DarkModernTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.todo == null ? 'New Task' : 'Edit Task',
          style: DarkModernTheme.titleLarge,
        ),
        actions: [
          if (!_isSaving)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: TextButton(
                onPressed: _saveTask,
                style: TextButton.styleFrom(
                  backgroundColor: DarkModernTheme.primary.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: DarkModernTheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(DarkModernTheme.primary),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input
            _buildInputCard(
              child: TextField(
                controller: _titleController,
                focusNode: _focusNode,
                style: DarkModernTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Task name',
                  hintStyle: TextStyle(color: DarkModernTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                autofocus: widget.todo == null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            const SizedBox(height: 12),

            // Note input
            _buildInputCard(
              child: TextField(
                controller: _noteController,
                style: DarkModernTheme.bodyMedium,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  hintStyle: TextStyle(color: DarkModernTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            const SizedBox(height: 16),

            // Due Date - Whole row is tappable
            _buildSectionTitle('Due Date'),
            _buildInputCard(
              child: GestureDetector(
                onTap: _dueDate == null ? _selectDueDate : null,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: _dueDate == null
                          ? DarkModernTheme.textSecondary
                          : DarkModernTheme.accentBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _dueDate == null
                            ? 'Add due date'
                            : DateFormat('MMM d, yyyy').format(_dueDate!),
                        style: DarkModernTheme.bodyMedium.copyWith(
                          color: _dueDate == null
                              ? DarkModernTheme.textSecondary
                              : Colors.white,
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            color: DarkModernTheme.textTertiary,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Priority
            _buildSectionTitle('Priority'),
            _buildInputCard(
              child: Row(
                children: Priority.values.map((p) {
                  final isSelected = _priority == p;
                  Color color;
                  String label;
                  switch (p) {
                    case Priority.low:
                      color = DarkModernTheme.accentGreen;
                      label = 'Low';
                      break;
                    case Priority.medium:
                      color = DarkModernTheme.accentYellow;
                      label = 'Medium';
                      break;
                    case Priority.high:
                      color = DarkModernTheme.accentRed;
                      label = 'High';
                      break;
                  }
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(DarkModernTheme.radiusSmall),
                          border: Border.all(
                            color: isSelected ? color : Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? color : DarkModernTheme.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // List selector
            _buildSectionTitle('List'),
            _buildInputCard(
              child: lists.isEmpty
                  ? GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Create a list first!'),
                            backgroundColor: DarkModernTheme.surface,
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: DarkModernTheme.primary,
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            color: DarkModernTheme.textTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No lists - tap to create one',
                              style: DarkModernTheme.bodyMedium.copyWith(
                                color: DarkModernTheme.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<TodoList>(
                        value: _selectedList ?? lists.first,
                        isExpanded: true,
                        dropdownColor: DarkModernTheme.surface,
                        style: DarkModernTheme.bodyMedium.copyWith(
                          color: Colors.white,
                        ),
                        iconEnabledColor: DarkModernTheme.textSecondary,
                        items: lists.map((list) {
                          return DropdownMenuItem<TodoList>(
                            value: list,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(list.color),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    list.name,
                                    style: DarkModernTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (list) {
                          if (list != null) {
                            setState(() => _selectedList = list);
                          }
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Subtasks
            _buildSectionTitle('Steps (optional)'),
            if (_subtasks.isNotEmpty) ...[
              ...List.generate(_subtasks.length, (index) {
                final subtask = _subtasks[index];
                return _buildSubtaskItem(subtask, index);
              }),
              const SizedBox(height: 12),
            ],

            // Add subtask input
            _buildInputCard(
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: DarkModernTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      style: DarkModernTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Add a step...',
                        hintStyle: TextStyle(color: DarkModernTheme.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _addSubtask(),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  GestureDetector(
                    onTap: _addSubtask,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.add,
                        color: DarkModernTheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarkModernTheme.surface.withOpacity(0.6),
            DarkModernTheme.surface.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSubtaskItem(SubTask subtask, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DarkModernTheme.surface.withOpacity(0.6),
            DarkModernTheme.surface.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _toggleSubtask(index),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: subtask.isCompleted
                      ? DarkModernTheme.accentGreen
                      : DarkModernTheme.textTertiary,
                  width: 2,
                ),
                color: subtask.isCompleted
                    ? DarkModernTheme.accentGreen.withOpacity(0.3)
                    : null,
              ),
              child: subtask.isCompleted
                  ? const Icon(Icons.check, color: DarkModernTheme.accentGreen, size: 12)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtask.title,
              style: DarkModernTheme.bodyMedium.copyWith(
                decoration: subtask.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: subtask.isCompleted
                    ? DarkModernTheme.textTertiary
                    : Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _subtasks.removeAt(index)),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close,
                color: DarkModernTheme.textTertiary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: DarkModernTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DarkModernTheme.primary,
              surface: DarkModernTheme.surface,
              onSurface: DarkModernTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() => _dueDate = date);
    }
  }

  void _addSubtask() {
    if (_subtaskController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _subtasks.add(SubTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _subtaskController.text.trim(),
        isCompleted: false,
      ));
      _subtaskController.clear();
    });
  }

  void _toggleSubtask(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _subtasks[index] = _subtasks[index].copyWith(
        isCompleted: !_subtasks[index].isCompleted,
      );
    });
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a task name'),
          backgroundColor: DarkModernTheme.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dataProvider = context.read<DataProvider>();
      final listId = _selectedList?.id ?? dataProvider.todoLists.first.id;

      if (widget.todo == null) {
        // Create new task
        final newTodo = Todo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          listId: listId,
          title: _titleController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          dueDate: _dueDate,
          priority: _priority,
          subtasks: _subtasks,
          order: dataProvider.todos.length,
          createdAt: DateTime.now(),
        );

        await dataProvider.createTodo(newTodo);
      } else {
        // Update existing task
        final updatedTodo = widget.todo!.copyWith(
          title: _titleController.text.trim(),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          dueDate: _dueDate,
          priority: _priority,
          subtasks: _subtasks,
        );

        await dataProvider.updateTodo(updatedTodo);
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: DarkModernTheme.accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
