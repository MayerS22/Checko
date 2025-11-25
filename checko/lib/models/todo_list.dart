class TodoList {
  final String id;
  final String name;
  final String? description;
  final int color;

  TodoList({
    required this.id,
    required this.name,
    this.description,
    this.color = 0xFF9C27B0, // Default purple color
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
    };
  }

  factory TodoList.fromMap(Map<String, dynamic> map) {
    return TodoList(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      color: map['color'] as int,
    );
  }
}
