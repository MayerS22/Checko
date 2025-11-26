import 'package:cloud_firestore/cloud_firestore.dart';

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

  // For Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory TodoList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TodoList(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String?,
      color: data['color'] as int,
    );
  }
}
