import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/todo.dart';
import '../theme/dark_modern_theme.dart';

/// Glassmorphism Task Item Widget
///
/// Features:
/// - Shows subtask progress
/// - Due date indicator
/// - Priority indicator
/// - Satisfying completion animation
/// - Compact design
class GlassTaskItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final bool isDark;

  const GlassTaskItem({
    super.key,
    required this.todo,
    required this.onToggle,
    this.onTap,
    this.isDark = true,
  });

  Color _getPriorityColor() {
    switch (todo.priority) {
      case Priority.high:
        return DarkModernTheme.accentRed;
      case Priority.medium:
        return DarkModernTheme.accentYellow;
      case Priority.low:
        return DarkModernTheme.accentGreen;
      default:
        return DarkModernTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSubtasks = todo.subtasks.isNotEmpty;
    final progress = todo.subtaskProgress;

    return Container(
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DarkModernTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Animated Circular checkbox
                  GestureDetector(
                    onTap: onToggle,
                    child: _AnimatedCheckbox(
                      isCompleted: todo.isCompleted,
                      color: DarkModernTheme.accentGreen,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Task content with strikethrough animation
                  Expanded(
                    child: _AnimatedTaskTitle(
                      title: todo.title,
                      note: todo.note,
                      isCompleted: todo.isCompleted,
                    ),
                  ),

                  // Priority, Due date, Subtasks
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          if (todo.priority != Priority.low)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPriorityColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                todo.priority.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: _getPriorityColor(),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (todo.dueDate != null) ...[
                            if (todo.priority != Priority.low) const SizedBox(width: 4),
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: todo.isOverdue
                                  ? DarkModernTheme.accentRed
                                  : DarkModernTheme.textTertiary,
                            ),
                          ],
                        ],
                      ),
                      if (hasSubtasks)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildSubtaskIndicator(progress),
                        ),
                    ],
                  ),
                ],
              ),

              // Subtask progress bar
              if (hasSubtasks) ...[
                const SizedBox(height: 8),
                _buildProgressBar(progress),
              ],
            ],
          ),
        ),
      ),
    )
        .animate(target: todo.isCompleted ? 1 : 0)
        .saturate(duration: 200.ms, curve: Curves.easeOut);
  }

  Widget _buildSubtaskIndicator(double progress) {
    final completed = todo.completedSubtasksCount;
    final total = todo.subtasks.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 12,
          color: progress == 1 ? DarkModernTheme.accentGreen : DarkModernTheme.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          '$completed/$total',
          style: TextStyle(
            color: progress == 1 ? DarkModernTheme.accentGreen : DarkModernTheme.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: DarkModernTheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: progress == 1 ? DarkModernTheme.accentGreen : DarkModernTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Animated Checkbox Widget
class _AnimatedCheckbox extends StatelessWidget {
  final bool isCompleted;
  final Color color;

  const _AnimatedCheckbox({
    required this.isCompleted,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted ? color : DarkModernTheme.textTertiary,
          width: 2,
        ),
        color: isCompleted ? color.withOpacity(0.2) : null,
      ),
      child: isCompleted
          ? Icon(Icons.check, color: color, size: 16)
              .animate()
              .scale(duration: 200.ms, begin: const Offset(0, 0), end: const Offset(1, 1))
              .then()
              .shimmer(duration: 400.ms, color: Colors.white.withOpacity(0.5))
          : null,
    )
        .animate(target: isCompleted ? 1 : 0)
        .scale(
          duration: 150.ms,
          begin: const Offset(1, 1),
          end: const Offset(1.15, 1.15),
          curve: Curves.easeOut,
        )
        .then()
        .scale(
          duration: 150.ms,
          begin: const Offset(1.15, 1.15),
          end: const Offset(1, 1),
          curve: Curves.easeIn,
        )
        .callback(duration: 300.ms, callback: (_) {
          // Optional: Add haptic feedback here
        });
  }
}

/// Animated Task Title Widget
class _AnimatedTaskTitle extends StatelessWidget {
  final String title;
  final String? note;
  final bool isCompleted;

  const _AnimatedTaskTitle({
    required this.title,
    required this.note,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DarkModernTheme.bodyLarge.copyWith(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? DarkModernTheme.textTertiary : null,
          ),
        )
            .animate(target: isCompleted ? 1 : 0)
            .fade(duration: 200.ms)
            .slideX(begin: 0.02, end: 0, duration: 200.ms),
        if (note != null && note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              note!,
              style: DarkModernTheme.bodySmall.copyWith(
                color: DarkModernTheme.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
