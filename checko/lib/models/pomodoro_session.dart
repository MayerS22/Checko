import 'package:cloud_firestore/cloud_firestore.dart';

enum PomodoroState {
  idle,
  working,
  shortBreak,
  longBreak,
  paused,
}

class PomodoroSession {
  final String id;
  final String? todoId;
  final String? todoTitle;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final bool completed;

  PomodoroSession({
    required this.id,
    this.todoId,
    this.todoTitle,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.completed = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'todoId': todoId,
      'todoTitle': todoTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'completed': completed,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory PomodoroSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PomodoroSession(
      id: doc.id,
      todoId: data['todoId'] as String?,
      todoTitle: data['todoTitle'] as String?,
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: data['endTime'] != null
          ? DateTime.parse(data['endTime'] as String)
          : null,
      durationMinutes: data['durationMinutes'] as int,
      completed: data['completed'] as bool? ?? false,
    );
  }

  // For local JSON storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todoId': todoId,
      'todoTitle': todoTitle,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'completed': completed,
    };
  }

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'] as String,
      todoId: json['todoId'] as String?,
      todoTitle: json['todoTitle'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int,
      completed: json['completed'] as bool? ?? false,
    );
  }

  PomodoroSession copyWith({
    String? id,
    String? todoId,
    String? todoTitle,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    bool? completed,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      todoTitle: todoTitle ?? this.todoTitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completed: completed ?? this.completed,
    );
  }
}


