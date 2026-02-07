import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/event.dart';
import '../models/tag.dart';
import '../models/pomodoro_session.dart';
import '../services/local_storage_service.dart';

/// Data provider using local storage for offline-first operation
/// Replaces FirestoreService for personal offline use
class DataProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService.instance;

  bool _initialized = false;
  List<Todo> _todos = [];
  List<TodoList> _todoLists = [];
  List<Event> _events = [];
  List<Tag> _tags = [];
  List<PomodoroSession> _pomodoroSessions = [];
  String? _username;

  // Getters
  bool get initialized => _initialized;
  List<Todo> get todos => _todos;
  List<TodoList> get todoLists => _todoLists;
  List<Event> get events => _events;
  List<Tag> get tags => _tags;
  List<PomodoroSession> get pomodoroSessions => _pomodoroSessions;
  String? get username => _username;

  /// Initialize the data provider
  Future<void> initialize() async {
    if (_initialized) return;

    await _storage.initialize();

    // Load all data
    await loadTodos();
    await loadTodoLists();
    await loadEvents();
    await loadTags();
    await loadPomodoroSessions();
    _username = await _storage.getUsername();

    // Create default list if none exists
    if (_todoLists.isEmpty) {
      await createTodoList(TodoList(
        id: 'default',
        name: 'My Tasks',
        color: 0xFF9C27B0,
      ));
    }

    _initialized = true;
    notifyListeners();
  }

  // ==================== TODOS ====================

  Future<void> loadTodos() async {
    _todos = await _storage.readAllTodos();
    notifyListeners();
  }

  Future<Todo> createTodo(Todo todo) async {
    final newTodo = await _storage.createTodo(todo);
    _todos.add(newTodo);
    notifyListeners();
    return newTodo;
  }

  Future<void> updateTodo(Todo todo) async {
    await _storage.updateTodo(todo);
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      notifyListeners();
    }
  }

  Future<void> deleteTodo(String id) async {
    await _storage.deleteTodo(id);
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  List<Todo> getTodosForList(String listId) {
    return _todos.where((t) => t.listId == listId).toList();
  }

  List<Todo> getCompletedTodos() {
    return _todos.where((t) => t.isCompleted).toList();
  }

  List<Todo> getIncompleteTodos() {
    return _todos.where((t) => !t.isCompleted).toList();
  }

  List<Todo> getFavoriteTodos() {
    return _todos.where((t) => t.isFavorite).toList();
  }

  // ==================== SMART LISTS (Microsoft To Do style) ====================

  /// Important: Tasks where isFavorite == true and not completed
  List<Todo> getImportantTodos() {
    return _todos.where((t) => t.isFavorite && !t.isCompleted).toList();
  }

  /// Planned: Tasks with dueDate != null and not completed
  List<Todo> getPlannedTodos() {
    return _todos.where((t) => t.dueDate != null && !t.isCompleted).toList();
  }

  /// All: All incomplete tasks
  List<Todo> getAllTodos() {
    return _todos.where((t) => !t.isCompleted).toList();
  }

  List<Todo> getOverdueTodos() {
    final now = DateTime.now();
    return _todos.where((t) =>
      !t.isCompleted &&
      t.dueDate != null &&
      t.dueDate!.isBefore(now)
    ).toList();
  }

  List<Todo> getTodaysTodos() {
    final now = DateTime.now();
    return _todos.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == now.year &&
             t.dueDate!.month == now.month &&
             t.dueDate!.day == now.day;
    }).toList();
  }

  // ==================== TODO LISTS ====================

  Future<void> loadTodoLists() async {
    _todoLists = await _storage.readAllTodoLists();
    notifyListeners();
  }

  Future<TodoList> createTodoList(TodoList todoList) async {
    final newList = await _storage.createTodoList(todoList);
    _todoLists.add(newList);
    notifyListeners();
    return newList;
  }

  Future<void> updateTodoList(TodoList todoList) async {
    await _storage.updateTodoList(todoList);
    final index = _todoLists.indexWhere((l) => l.id == todoList.id);
    if (index != -1) {
      _todoLists[index] = todoList;
      notifyListeners();
    }
  }

  Future<void> deleteTodoList(String id) async {
    await _storage.deleteTodoList(id);
    _todoLists.removeWhere((l) => l.id == id);
    _todos.removeWhere((t) => t.listId == id);
    notifyListeners();
  }

  TodoList? getTodoListById(String id) {
    try {
      return _todoLists.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  // ==================== EVENTS ====================

  Future<void> loadEvents() async {
    _events = await _storage.readAllEvents();
    notifyListeners();
  }

  Future<Event> createEvent(Event event) async {
    final newEvent = await _storage.createEvent(event);
    _events.add(newEvent);
    notifyListeners();
    return newEvent;
  }

  Future<void> updateEvent(Event event) async {
    await _storage.updateEvent(event);
    final index = _events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      _events[index] = event;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    await _storage.deleteEvent(id);
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  List<Event> getEventsForDate(DateTime date) {
    return _events.where((e) =>
      e.startTime.year == date.year &&
      e.startTime.month == date.month &&
      e.startTime.day == date.day
    ).toList();
  }

  List<Event> getUpcomingEvents({Duration within = const Duration(days: 7)}) {
    final now = DateTime.now();
    final end = now.add(within);
    return _events.where((e) =>
      e.startTime.isAfter(now) &&
      e.startTime.isBefore(end)
    ).toList();
  }

  List<Event> getPastEvents() {
    final now = DateTime.now();
    return _events.where((e) => e.endTime.isBefore(now)).toList();
  }

  List<Event> getCurrentEvents() {
    final now = DateTime.now();
    return _events.where((e) =>
      e.startTime.isBefore(now) && e.endTime.isAfter(now)
    ).toList();
  }

  // ==================== TAGS ====================

  Future<void> loadTags() async {
    _tags = await _storage.readAllTags();
    // Add default tags if none exist
    if (_tags.isEmpty) {
      _tags = Tag.defaultTags;
      for (final tag in _tags) {
        await _storage.createTag(tag);
      }
    }
    notifyListeners();
  }

  Future<Tag> createTag(Tag tag) async {
    final newTag = await _storage.createTag(tag);
    _tags.add(newTag);
    notifyListeners();
    return newTag;
  }

  Future<void> updateTag(Tag tag) async {
    await _storage.updateTag(tag);
    final index = _tags.indexWhere((t) => t.id == tag.id);
    if (index != -1) {
      _tags[index] = tag;
      notifyListeners();
    }
  }

  Future<void> deleteTag(String id) async {
    await _storage.deleteTag(id);
    _tags.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Tag? getTagById(String id) {
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // ==================== POMODORO SESSIONS ====================

  Future<void> loadPomodoroSessions() async {
    _pomodoroSessions = await _storage.readPomodoroSessions();
    notifyListeners();
  }

  Future<PomodoroSession> createPomodoroSession(PomodoroSession session) async {
    final newSession = await _storage.createPomodoroSession(session);
    _pomodoroSessions.add(newSession);
    notifyListeners();
    return newSession;
  }

  List<PomodoroSession> getPomodoroSessionsForTodo(String todoId) {
    return _pomodoroSessions.where((s) => s.todoId == todoId).toList();
  }

  List<PomodoroSession> getPomodoroSessionsForDate(DateTime date) {
    return _pomodoroSessions.where((s) =>
      s.startTime.year == date.year &&
      s.startTime.month == date.month &&
      s.startTime.day == date.day
    ).toList();
  }

  int getTotalPomodoroMinutes() {
    return _pomodoroSessions
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  // ==================== USER SETTINGS ====================

  Future<void> setUsername(String username) async {
    await _storage.setUsername(username);
    _username = username;
    notifyListeners();
  }

  // ==================== UTILITIES ====================

  /// Export all data as JSON
  Future<String> exportData() async {
    return await _storage.exportData();
  }

  /// Import data from JSON
  Future<void> importData(String jsonData) async {
    await _storage.importData(jsonData);
    await initialize();
  }

  /// Clear all data
  Future<void> clearAll() async {
    await _storage.clearAll();
    _todos.clear();
    _todoLists.clear();
    _events.clear();
    _tags.clear();
    _pomodoroSessions.clear();
    _username = null;
    notifyListeners();
  }
}
