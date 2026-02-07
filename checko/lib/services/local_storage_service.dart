import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/event.dart';
import '../models/tag.dart';
import '../models/user_settings.dart';
import '../models/pomodoro_session.dart';

/// Offline-first storage service using SharedPreferences
/// Works completely offline without requiring Firebase
class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._init();
  LocalStorageService._init();

  static const String _todosKey = 'todos';
  static const String _todoListsKey = 'todo_lists';
  static const String _eventsKey = 'events';
  static const String _tagsKey = 'tags';
  static const String _settingsKey = 'user_settings';
  static const String _pomodoroSessionsKey = 'pomodoro_sessions';
  static const String _usernameKey = 'username';
  static const String _themeKey = 'is_dark_mode';

  SharedPreferences? _prefs;

  /// Initialize the storage service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ==================== HELPERS ====================

  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  List<T> _decodeList<T>(String? json, T Function(dynamic) fromJson) {
    if (json == null || json.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.map((item) => fromJson(item)).toList();
  }

  String _encodeList(List<dynamic> items) {
    return jsonEncode(items);
  }

  // ==================== TODOS ====================

  Future<List<Todo>> readAllTodos() async {
    await _ensureInitialized();
    final json = _prefs!.getString(_todosKey);
    return _decodeList(json, (data) => Todo.fromJson(data));
  }

  Future<Todo> createTodo(Todo todo) async {
    await _ensureInitialized();
    final todos = await readAllTodos();
    final newTodo = todo.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );
    todos.add(newTodo);
    await _prefs!.setString(_todosKey, _encodeList(todos.map((t) => t.toJson()).toList()));
    return newTodo;
  }

  Future<void> updateTodo(Todo todo) async {
    await _ensureInitialized();
    final todos = await readAllTodos();
    final index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      todos[index] = todo;
      await _prefs!.setString(_todosKey, _encodeList(todos.map((t) => t.toJson()).toList()));
    }
  }

  Future<void> deleteTodo(String id) async {
    await _ensureInitialized();
    final todos = await readAllTodos();
    todos.removeWhere((t) => t.id == id);
    await _prefs!.setString(_todosKey, _encodeList(todos.map((t) => t.toJson()).toList()));
  }

  // ==================== TODO LISTS ====================

  Future<List<TodoList>> readAllTodoLists() async {
    await _ensureInitialized();
    final json = _prefs!.getString(_todoListsKey);
    return _decodeList(json, (data) => TodoList.fromJson(data));
  }

  Future<TodoList> createTodoList(TodoList todoList) async {
    await _ensureInitialized();
    final lists = await readAllTodoLists();
    final newList = todoList.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    lists.add(newList);
    await _prefs!.setString(_todoListsKey, _encodeList(lists.map((l) => l.toJson()).toList()));
    return newList;
  }

  Future<void> updateTodoList(TodoList todoList) async {
    await _ensureInitialized();
    final lists = await readAllTodoLists();
    final index = lists.indexWhere((l) => l.id == todoList.id);
    if (index != -1) {
      lists[index] = todoList;
      await _prefs!.setString(_todoListsKey, _encodeList(lists.map((l) => l.toJson()).toList()));
    }
  }

  Future<void> deleteTodoList(String id) async {
    await _ensureInitialized();
    final lists = await readAllTodoLists();
    lists.removeWhere((l) => l.id == id);
    await _prefs!.setString(_todoListsKey, _encodeList(lists.map((l) => l.toJson()).toList()));
    // Also delete all todos in this list
    final todos = await readAllTodos();
    todos.removeWhere((t) => t.listId == id);
    await _prefs!.setString(_todosKey, _encodeList(todos.map((t) => t.toJson()).toList()));
  }

  // ==================== EVENTS ====================

  Future<List<Event>> readAllEvents() async {
    await _ensureInitialized();
    final json = _prefs!.getString(_eventsKey);
    return _decodeList(json, (data) => Event.fromJson(data));
  }

  Future<Event> createEvent(Event event) async {
    await _ensureInitialized();
    final events = await readAllEvents();
    final newEvent = Event(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: event.title,
      description: event.description,
      startTime: event.startTime,
      endTime: event.endTime,
      calendarId: event.calendarId,
      eventColor: event.eventColor,
      recurrence: event.recurrence,
      reminders: event.reminders,
      attendees: event.attendees,
      location: event.location,
      conferenceUrl: event.conferenceUrl,
      privacy: event.privacy,
      status: event.status,
      availability: event.availability,
      transparency: event.transparency,
      createdAt: DateTime.now(),
      modifiedAt: event.modifiedAt,
      createdBy: event.createdBy,
    );
    events.add(newEvent);
    await _prefs!.setString(_eventsKey, _encodeList(events.map((e) => e.toJson()).toList()));
    return newEvent;
  }

  Future<void> updateEvent(Event event) async {
    await _ensureInitialized();
    final events = await readAllEvents();
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      await _prefs!.setString(_eventsKey, _encodeList(events.map((e) => e.toJson()).toList()));
    }
  }

  Future<void> deleteEvent(String id) async {
    await _ensureInitialized();
    final events = await readAllEvents();
    events.removeWhere((e) => e.id == id);
    await _prefs!.setString(_eventsKey, _encodeList(events.map((e) => e.toJson()).toList()));
  }

  // ==================== TAGS ====================

  Future<List<Tag>> readAllTags() async {
    await _ensureInitialized();
    final json = _prefs!.getString(_tagsKey);
    return _decodeList(json, (data) => Tag.fromJson(data));
  }

  Future<Tag> createTag(Tag tag) async {
    await _ensureInitialized();
    final tags = await readAllTags();
    final newTag = tag.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    tags.add(newTag);
    await _prefs!.setString(_tagsKey, _encodeList(tags.map((t) => t.toJson()).toList()));
    return newTag;
  }

  Future<void> updateTag(Tag tag) async {
    await _ensureInitialized();
    final tags = await readAllTags();
    final index = tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      tags[index] = tag;
      await _prefs!.setString(_tagsKey, _encodeList(tags.map((t) => t.toJson()).toList()));
    }
  }

  Future<void> deleteTag(String id) async {
    await _ensureInitialized();
    final tags = await readAllTags();
    tags.removeWhere((t) => t.id == id);
    await _prefs!.setString(_tagsKey, _encodeList(tags.map((t) => t.toJson()).toList()));
  }

  // ==================== USER SETTINGS ====================

  Future<String?> getUsername() async {
    await _ensureInitialized();
    return _prefs!.getString(_usernameKey);
  }

  Future<void> setUsername(String username) async {
    await _ensureInitialized();
    await _prefs!.setString(_usernameKey, username);
  }

  Future<bool> isDarkMode() async {
    await _ensureInitialized();
    return _prefs!.getBool(_themeKey) ?? true;
  }

  Future<void> setDarkMode(bool isDark) async {
    await _ensureInitialized();
    await _prefs!.setBool(_themeKey, isDark);
  }

  // ==================== POMODORO SESSIONS ====================

  Future<List<PomodoroSession>> readPomodoroSessions() async {
    await _ensureInitialized();
    final json = _prefs!.getString(_pomodoroSessionsKey);
    return _decodeList(json, (data) => PomodoroSession.fromJson(data));
  }

  Future<PomodoroSession> createPomodoroSession(PomodoroSession session) async {
    await _ensureInitialized();
    final sessions = await readPomodoroSessions();
    final newSession = session.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    sessions.add(newSession);
    await _prefs!.setString(_pomodoroSessionsKey, _encodeList(sessions.map((s) => s.toJson()).toList()));
    return newSession;
  }

  // ==================== CLEAR DATA ====================

  Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs!.clear();
  }

  /// Export all data as JSON string
  Future<String> exportData() async {
    await _ensureInitialized();
    final data = {
      'todos': (await readAllTodos()).map((t) => t.toJson()).toList(),
      'todoLists': (await readAllTodoLists()).map((l) => l.toJson()).toList(),
      'events': (await readAllEvents()).map((e) => e.toJson()).toList(),
      'tags': (await readAllTags()).map((t) => t.toJson()).toList(),
      'pomodoroSessions': (await readPomodoroSessions()).map((s) => s.toJson()).toList(),
      'username': await getUsername(),
      'isDarkMode': await isDarkMode(),
    };
    return jsonEncode(data);
  }

  /// Import data from JSON string
  Future<void> importData(String jsonData) async {
    await _ensureInitialized();
    final data = jsonDecode(jsonData) as Map<String, dynamic>;

    if (data['todos'] != null) {
      await _prefs!.setString(_todosKey, jsonEncode(data['todos']));
    }
    if (data['todoLists'] != null) {
      await _prefs!.setString(_todoListsKey, jsonEncode(data['todoLists']));
    }
    if (data['events'] != null) {
      await _prefs!.setString(_eventsKey, jsonEncode(data['events']));
    }
    if (data['tags'] != null) {
      await _prefs!.setString(_tagsKey, jsonEncode(data['tags']));
    }
    if (data['pomodoroSessions'] != null) {
      await _prefs!.setString(_pomodoroSessionsKey, jsonEncode(data['pomodoroSessions']));
    }
    if (data['username'] != null) {
      await _prefs!.setString(_usernameKey, data['username']);
    }
    if (data['isDarkMode'] != null) {
      await _prefs!.setBool(_themeKey, data['isDarkMode']);
    }
  }
}
