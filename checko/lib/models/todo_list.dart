import 'package:cloud_firestore/cloud_firestore.dart';

class TodoList {
  final String id;
  final String name;
  final String? description;
  final int color;
  final String? icon; // Icon name for Microsoft To Do style
  final String? backgroundColor; // Optional hex background color

  TodoList({
    required this.id,
    required this.name,
    this.description,
    this.color = 0xFF9C27B0, // Default purple color
    this.icon,
    this.backgroundColor,
  });

  // For Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'backgroundColor': backgroundColor,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory TodoList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TodoList(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String?,
      color: data['color'] as int? ?? 0xFF9C27B0,
      icon: data['icon'] as String?,
      backgroundColor: data['backgroundColor'] as String?,
    );
  }

  // For local JSON storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'backgroundColor': backgroundColor,
    };
  }

  factory TodoList.fromJson(Map<String, dynamic> json) {
    return TodoList(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as int? ?? 0xFF9C27B0,
      icon: json['icon'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
    );
  }

  TodoList copyWith({
    String? id,
    String? name,
    String? description,
    int? color,
    String? icon,
    String? backgroundColor,
  }) {
    return TodoList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
