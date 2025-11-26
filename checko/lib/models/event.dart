import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  bool isCompleted;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.isCompleted = false,
  });

  // For Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'isCompleted': isCompleted,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String?,
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: DateTime.parse(data['endTime'] as String),
      location: data['location'] as String?,
      isCompleted: data['isCompleted'] as bool,
    );
  }
}
