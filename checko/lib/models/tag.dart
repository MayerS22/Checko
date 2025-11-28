import 'package:cloud_firestore/cloud_firestore.dart';

class Tag {
  final String id;
  final String name;
  final int color;

  Tag({
    required this.id,
    required this.name,
    this.color = 0xFF7c5dfa,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Tag.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Tag(
      id: doc.id,
      name: data['name'] as String,
      color: data['color'] as int? ?? 0xFF7c5dfa,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as int? ?? 0xFF7c5dfa,
    );
  }

  // Predefined tags for quick use
  static List<Tag> get defaultTags => [
    Tag(id: 'work', name: 'Work', color: 0xFF2196F3),
    Tag(id: 'personal', name: 'Personal', color: 0xFF4CAF50),
    Tag(id: 'urgent', name: 'Urgent', color: 0xFFF44336),
    Tag(id: 'health', name: 'Health', color: 0xFFE91E63),
    Tag(id: 'finance', name: 'Finance', color: 0xFFFF9800),
    Tag(id: 'learning', name: 'Learning', color: 0xFF9C27B0),
  ];
}


