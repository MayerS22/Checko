import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../theme/ms_todo_colors.dart';

/// Microsoft To Do style task item widget
///
/// Simplified, clean design with:
/// - Circular checkbox
/// - Clean typography
/// - Due dates inline
/// - Subtasks indicator
/// - Star for important
class MSTodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onFavorite;
  final bool isDark;

  const MSTodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    this.onFavorite,
    required this.isDark,
  });

  Color get _textColor => todo.isCompleted
      ? MSToDoColors.msTextSecondary
      : (isDark ? MSToDoColors.msTextPrimaryDark : MSToDoColors.msTextPrimary);

  Color get _backgroundColor => isDark
      ? MSToDoColors.msSurfaceDark
      : MSToDoColors.msSurface;

  Color get _borderColor => isDark
      ? MSToDoColors.msBorderDark
      : MSToDoColors.msBorder;

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

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('todo-${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: MSToDoColors.error,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: InkWell(
          onTap: () {
            // Show task details
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: todo.isCompleted
                            ? MSToDoColors.success
                            : MSToDoColors.msTextSecondary,
                        width: 2,
                      ),
                      color: todo.isCompleted ? MSToDoColors.success : null,
                    ),
                    child: todo.isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (todo.subtasks.isNotEmpty || todo.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (todo.subtasks.isNotEmpty) ...[
                                Text(
                                  '${todo.completedSubtasksCount}/${todo.subtasks.length}',
                                  style: TextStyle(
                                    color: MSToDoColors.msTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (todo.dueDate != null) ...[
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: todo.isOverdue ? MSToDoColors.error : MSToDoColors.msTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(todo.dueDate!),
                                  style: TextStyle(
                                    color: todo.isOverdue ? MSToDoColors.error : MSToDoColors.msTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Favorite action
                if (onFavorite != null)
                  GestureDetector(
                    onTap: onFavorite,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        todo.isFavorite ? Icons.star : Icons.star_border,
                        color: todo.isFavorite ? MSToDoColors.warning : MSToDoColors.msTextSecondary,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
