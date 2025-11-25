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

  Todo({
    required this.id,
    required this.listId,
    required this.title,
    this.note,
    this.dueDate,
    this.priority = Priority.medium,
    this.isCompleted = false,
    this.isFavorite = false,
  });

  void toggleComplete() {
    isCompleted = !isCompleted;
  }

  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listId': listId,
      'title': title,
      'note': note,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.index,
      'isCompleted': isCompleted ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      listId: map['listId'] as String,
      title: map['title'] as String,
      note: map['note'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      priority: Priority.values[map['priority'] as int],
      isCompleted: map['isCompleted'] == 1,
      isFavorite: map['isFavorite'] == 1,
    );
  }
}

