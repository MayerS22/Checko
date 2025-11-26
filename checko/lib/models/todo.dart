import 'package:cloud_firestore/cloud_firestore.dart';
import 'subtask.dart';
import 'tag.dart';
import 'recurrence.dart';

enum Priority { low, medium, high }

class Todo {
  final String id;
  final String listId;
  final String title;
  final String? note;
  final DateTime? dueDate;
  final Priority priority;
  bool isCompleted;
  bool isFavorite;
  List<SubTask> subtasks;
  List<Tag> tags;
  RecurrenceRule recurrence;
  DateTime? completedAt;
  DateTime createdAt;
  int order; // For drag-drop reordering
  int pomodoroSessions; // Track focus time

  Todo({
    required this.id,
    required this.listId,
    required this.title,
    this.note,
    this.dueDate,
    this.priority = Priority.medium,
    this.isCompleted = false,
    this.isFavorite = false,
    List<SubTask>? subtasks,
    List<Tag>? tags,
    RecurrenceRule? recurrence,
    this.completedAt,
    DateTime? createdAt,
    this.order = 0,
    this.pomodoroSessions = 0,
  })  : subtasks = subtasks ?? [],
        tags = tags ?? [],
        recurrence = recurrence ?? RecurrenceRule(),
        createdAt = createdAt ?? DateTime.now();

  void toggleComplete() {
    isCompleted = !isCompleted;
    completedAt = isCompleted ? DateTime.now() : null;
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  void addSubtask(SubTask subtask) {
    subtasks.add(subtask);
  }

  void removeSubtask(String subtaskId) {
    subtasks.removeWhere((s) => s.id == subtaskId);
  }

  void addTag(Tag tag) {
    if (!tags.any((t) => t.id == tag.id)) {
      tags.add(tag);
    }
  }

  void removeTag(String tagId) {
    tags.removeWhere((t) => t.id == tagId);
  }

  int get completedSubtasksCount =>
      subtasks.where((s) => s.isCompleted).length;

  double get subtaskProgress =>
      subtasks.isEmpty ? 0 : completedSubtasksCount / subtasks.length;

  bool get isOverdue =>
      dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
  }

  // For Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'listId': listId,
      'title': title,
      'note': note,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.index,
      'isCompleted': isCompleted,
      'isFavorite': isFavorite,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'tags': tags.map((t) => t.toMap()).toList(),
      'recurrence': recurrence.toMap(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
      'order': order,
      'pomodoroSessions': pomodoroSessions,
    };
  }

  factory Todo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final subtasksList = data['subtasks'] as List<dynamic>? ?? [];
    final tagsList = data['tags'] as List<dynamic>? ?? [];

    return Todo(
      id: doc.id,
      listId: data['listId'] as String,
      title: data['title'] as String,
      note: data['note'] as String?,
      dueDate: data['dueDate'] != null
          ? DateTime.parse(data['dueDate'] as String)
          : null,
      priority: Priority.values[data['priority'] as int? ?? 1],
      isCompleted: data['isCompleted'] as bool? ?? false,
      isFavorite: data['isFavorite'] as bool? ?? false,
      subtasks: subtasksList
          .map((s) => SubTask.fromMap(s as Map<String, dynamic>))
          .toList(),
      tags: tagsList.map((t) => Tag.fromMap(t as Map<String, dynamic>)).toList(),
      recurrence: RecurrenceRule.fromMap(data['recurrence'] as Map<String, dynamic>?),
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'] as String)
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      order: data['order'] as int? ?? 0,
      pomodoroSessions: data['pomodoroSessions'] as int? ?? 0,
    );
  }

  Todo copyWith({
    String? id,
    String? listId,
    String? title,
    String? note,
    DateTime? dueDate,
    Priority? priority,
    bool? isCompleted,
    bool? isFavorite,
    List<SubTask>? subtasks,
    List<Tag>? tags,
    RecurrenceRule? recurrence,
    DateTime? completedAt,
    DateTime? createdAt,
    int? order,
    int? pomodoroSessions,
  }) {
    return Todo(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      title: title ?? this.title,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      subtasks: subtasks ?? this.subtasks,
      tags: tags ?? this.tags,
      recurrence: recurrence ?? this.recurrence,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
      pomodoroSessions: pomodoroSessions ?? this.pomodoroSessions,
    );
  }
}
