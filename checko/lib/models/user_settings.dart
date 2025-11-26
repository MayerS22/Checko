import 'package:cloud_firestore/cloud_firestore.dart';

class UserSettings {
  final String id;
  String username;
  String? avatarUrl;
  bool isDarkMode;
  int pomodoroWorkDuration; // in minutes
  int pomodoroBreakDuration; // in minutes
  int pomodoroLongBreakDuration; // in minutes
  int pomodoroSessionsBeforeLongBreak;
  bool soundEnabled;
  bool vibrationEnabled;
  DateTime? lastActiveDate;
  int currentStreak;
  int longestStreak;
  int totalTasksCompleted;
  List<String> achievements;

  UserSettings({
    required this.id,
    this.username = 'User',
    this.avatarUrl,
    this.isDarkMode = true,
    this.pomodoroWorkDuration = 25,
    this.pomodoroBreakDuration = 5,
    this.pomodoroLongBreakDuration = 15,
    this.pomodoroSessionsBeforeLongBreak = 4,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.lastActiveDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalTasksCompleted = 0,
    List<String>? achievements,
  }) : achievements = achievements ?? [];

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'avatarUrl': avatarUrl,
      'isDarkMode': isDarkMode,
      'pomodoroWorkDuration': pomodoroWorkDuration,
      'pomodoroBreakDuration': pomodoroBreakDuration,
      'pomodoroLongBreakDuration': pomodoroLongBreakDuration,
      'pomodoroSessionsBeforeLongBreak': pomodoroSessionsBeforeLongBreak,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalTasksCompleted': totalTasksCompleted,
      'achievements': achievements,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return UserSettings(id: doc.id);
    }
    return UserSettings(
      id: doc.id,
      username: data['username'] as String? ?? 'User',
      avatarUrl: data['avatarUrl'] as String?,
      isDarkMode: data['isDarkMode'] as bool? ?? true,
      pomodoroWorkDuration: data['pomodoroWorkDuration'] as int? ?? 25,
      pomodoroBreakDuration: data['pomodoroBreakDuration'] as int? ?? 5,
      pomodoroLongBreakDuration: data['pomodoroLongBreakDuration'] as int? ?? 15,
      pomodoroSessionsBeforeLongBreak: data['pomodoroSessionsBeforeLongBreak'] as int? ?? 4,
      soundEnabled: data['soundEnabled'] as bool? ?? true,
      vibrationEnabled: data['vibrationEnabled'] as bool? ?? true,
      lastActiveDate: data['lastActiveDate'] != null
          ? DateTime.parse(data['lastActiveDate'] as String)
          : null,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      totalTasksCompleted: data['totalTasksCompleted'] as int? ?? 0,
      achievements: (data['achievements'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  UserSettings copyWith({
    String? username,
    String? avatarUrl,
    bool? isDarkMode,
    int? pomodoroWorkDuration,
    int? pomodoroBreakDuration,
    int? pomodoroLongBreakDuration,
    int? pomodoroSessionsBeforeLongBreak,
    bool? soundEnabled,
    bool? vibrationEnabled,
    DateTime? lastActiveDate,
    int? currentStreak,
    int? longestStreak,
    int? totalTasksCompleted,
    List<String>? achievements,
  }) {
    return UserSettings(
      id: id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      pomodoroWorkDuration: pomodoroWorkDuration ?? this.pomodoroWorkDuration,
      pomodoroBreakDuration: pomodoroBreakDuration ?? this.pomodoroBreakDuration,
      pomodoroLongBreakDuration: pomodoroLongBreakDuration ?? this.pomodoroLongBreakDuration,
      pomodoroSessionsBeforeLongBreak: pomodoroSessionsBeforeLongBreak ?? this.pomodoroSessionsBeforeLongBreak,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      achievements: achievements ?? this.achievements,
    );
  }
}

// Achievement definitions
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requirement;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requirement,
  });

  static const List<Achievement> allAchievements = [
    Achievement(
      id: 'first_task',
      title: 'First Step',
      description: 'Complete your first task',
      icon: '🎯',
      requirement: 1,
    ),
    Achievement(
      id: 'ten_tasks',
      title: 'Getting Started',
      description: 'Complete 10 tasks',
      icon: '🌟',
      requirement: 10,
    ),
    Achievement(
      id: 'fifty_tasks',
      title: 'Productivity Pro',
      description: 'Complete 50 tasks',
      icon: '🏆',
      requirement: 50,
    ),
    Achievement(
      id: 'hundred_tasks',
      title: 'Task Master',
      description: 'Complete 100 tasks',
      icon: '👑',
      requirement: 100,
    ),
    Achievement(
      id: 'streak_3',
      title: 'On a Roll',
      description: 'Maintain a 3-day streak',
      icon: '🔥',
      requirement: 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      icon: '💪',
      requirement: 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Monthly Master',
      description: 'Maintain a 30-day streak',
      icon: '🌙',
      requirement: 30,
    ),
    Achievement(
      id: 'pomodoro_1',
      title: 'Focus Beginner',
      description: 'Complete your first Pomodoro session',
      icon: '🍅',
      requirement: 1,
    ),
    Achievement(
      id: 'pomodoro_10',
      title: 'Focus Champion',
      description: 'Complete 10 Pomodoro sessions',
      icon: '⏱️',
      requirement: 10,
    ),
  ];
}

