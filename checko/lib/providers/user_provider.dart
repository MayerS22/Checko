import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import '../database/firestore_service.dart';

class UserProvider extends ChangeNotifier {
  UserSettings? _settings;
  bool _isLoading = true;
  SharedPreferences? _prefs;

  UserSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String get username => _settings?.username ?? 'Mayoor';
  int get currentStreak => _settings?.currentStreak ?? 0;
  int get longestStreak => _settings?.longestStreak ?? 0;
  int get totalTasksCompleted => _settings?.totalTasksCompleted ?? 0;
  List<String> get achievements => _settings?.achievements ?? [];

  UserProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();

      // Try to load from Firestore first
      _settings = await FirestoreService.instance.getUserSettings();

      // Save to local storage as backup
      await _saveToLocal();
    } catch (e) {
      print('Failed to load from Firestore, using local storage: $e');

      // Load from local storage
      await _loadFromLocal();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromLocal() async {
    _prefs ??= await SharedPreferences.getInstance();

    final username = _prefs!.getString('username') ?? 'Mayoor';
    final currentStreak = _prefs!.getInt('currentStreak') ?? 0;
    final longestStreak = _prefs!.getInt('longestStreak') ?? 0;
    final totalTasks = _prefs!.getInt('totalTasksCompleted') ?? 0;
    final achievements = _prefs!.getStringList('achievements') ?? [];

    _settings = UserSettings(
      id: 'local',
      username: username,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalTasksCompleted: totalTasks,
      achievements: achievements,
    );
  }

  Future<void> _saveToLocal() async {
    if (_settings == null || _prefs == null) return;

    await _prefs!.setString('username', _settings!.username);
    await _prefs!.setInt('currentStreak', _settings!.currentStreak);
    await _prefs!.setInt('longestStreak', _settings!.longestStreak);
    await _prefs!.setInt('totalTasksCompleted', _settings!.totalTasksCompleted);
    await _prefs!.setStringList('achievements', _settings!.achievements);
  }

  Future<void> updateUsername(String username) async {
    if (_settings == null) {
      print('Settings is null, creating new settings');
      _settings = UserSettings(
        id: 'local',
        username: username,
      );
    } else {
      _settings = _settings!.copyWith(username: username);
    }

    print('Updating username to: $username');

    // Save to local storage first
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('username', username);

    // Try to save to Firestore if available
    try {
      await FirestoreService.instance.updateUserSettings(_settings!);
      print('Username updated successfully in Firestore');
    } catch (e) {
      print('Failed to save to Firestore, saved locally: $e');
    }

    notifyListeners();
  }

  Future<void> updatePomodoroSettings({
    int? workDuration,
    int? breakDuration,
    int? longBreakDuration,
    int? sessionsBeforeLongBreak,
  }) async {
    if (_settings == null) return;
    _settings = _settings!.copyWith(
      pomodoroWorkDuration: workDuration,
      pomodoroBreakDuration: breakDuration,
      pomodoroLongBreakDuration: longBreakDuration,
      pomodoroSessionsBeforeLongBreak: sessionsBeforeLongBreak,
    );
    await FirestoreService.instance.updateUserSettings(_settings!);
    notifyListeners();
  }

  Future<void> updateSoundSettings({bool? soundEnabled, bool? vibrationEnabled}) async {
    if (_settings == null) return;
    _settings = _settings!.copyWith(
      soundEnabled: soundEnabled,
      vibrationEnabled: vibrationEnabled,
    );
    await FirestoreService.instance.updateUserSettings(_settings!);
    notifyListeners();
  }

  Future<void> incrementTasksCompleted() async {
    if (_settings == null) return;
    
    final newTotal = _settings!.totalTasksCompleted + 1;
    _settings = _settings!.copyWith(totalTasksCompleted: newTotal);
    
    // Check for achievements
    await _checkAndUnlockAchievements();
    
    await FirestoreService.instance.updateUserSettings(_settings!);
    notifyListeners();
  }

  Future<void> updateStreak() async {
    if (_settings == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = _settings!.lastActiveDate;

    if (lastActive == null) {
      // First time using the app
      _settings = _settings!.copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastActiveDate: today,
      );
    } else {
      final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final difference = today.difference(lastActiveDay).inDays;

      if (difference == 0) {
        // Same day, no update needed
        return;
      } else if (difference == 1) {
        // Consecutive day - increment streak
        final newStreak = _settings!.currentStreak + 1;
        final newLongest = newStreak > _settings!.longestStreak
            ? newStreak
            : _settings!.longestStreak;
        _settings = _settings!.copyWith(
          currentStreak: newStreak,
          longestStreak: newLongest,
          lastActiveDate: today,
        );
      } else {
        // Streak broken - reset to 1
        _settings = _settings!.copyWith(
          currentStreak: 1,
          lastActiveDate: today,
        );
      }
    }

    await _checkAndUnlockAchievements();
    await FirestoreService.instance.updateUserSettings(_settings!);
    notifyListeners();
  }

  Future<void> _checkAndUnlockAchievements() async {
    if (_settings == null) return;

    final newAchievements = List<String>.from(_settings!.achievements);
    bool hasNewAchievement = false;

    // Check task completion achievements
    if (_settings!.totalTasksCompleted >= 1 && !newAchievements.contains('first_task')) {
      newAchievements.add('first_task');
      hasNewAchievement = true;
    }
    if (_settings!.totalTasksCompleted >= 10 && !newAchievements.contains('ten_tasks')) {
      newAchievements.add('ten_tasks');
      hasNewAchievement = true;
    }
    if (_settings!.totalTasksCompleted >= 50 && !newAchievements.contains('fifty_tasks')) {
      newAchievements.add('fifty_tasks');
      hasNewAchievement = true;
    }
    if (_settings!.totalTasksCompleted >= 100 && !newAchievements.contains('hundred_tasks')) {
      newAchievements.add('hundred_tasks');
      hasNewAchievement = true;
    }

    // Check streak achievements
    if (_settings!.currentStreak >= 3 && !newAchievements.contains('streak_3')) {
      newAchievements.add('streak_3');
      hasNewAchievement = true;
    }
    if (_settings!.currentStreak >= 7 && !newAchievements.contains('streak_7')) {
      newAchievements.add('streak_7');
      hasNewAchievement = true;
    }
    if (_settings!.currentStreak >= 30 && !newAchievements.contains('streak_30')) {
      newAchievements.add('streak_30');
      hasNewAchievement = true;
    }

    if (hasNewAchievement) {
      _settings = _settings!.copyWith(achievements: newAchievements);
    }
  }

  Future<void> addPomodoroAchievement(int totalSessions) async {
    if (_settings == null) return;

    final newAchievements = List<String>.from(_settings!.achievements);
    bool hasNewAchievement = false;

    if (totalSessions >= 1 && !newAchievements.contains('pomodoro_1')) {
      newAchievements.add('pomodoro_1');
      hasNewAchievement = true;
    }
    if (totalSessions >= 10 && !newAchievements.contains('pomodoro_10')) {
      newAchievements.add('pomodoro_10');
      hasNewAchievement = true;
    }

    if (hasNewAchievement) {
      _settings = _settings!.copyWith(achievements: newAchievements);
      await FirestoreService.instance.updateUserSettings(_settings!);
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadSettings();
  }
}

