import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/event.dart';
import '../models/tag.dart';
import '../models/user_settings.dart';
import '../models/pomodoro_session.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService._init();

  // Get current user ID - use local storage if Firebase Auth is not configured
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? 'local_user';

  // Public getter for user ID
  String get userId => _userId;

  // Collection references
  CollectionReference get _todoListsCollection => _firestore.collection('todo_lists');
  CollectionReference get _todosCollection => _firestore.collection('todos');
  CollectionReference get _eventsCollection => _firestore.collection('events');
  CollectionReference get _tagsCollection => _firestore.collection('tags');
  CollectionReference get _userSettingsCollection => _firestore.collection('user_settings');
  CollectionReference get _pomodoroSessionsCollection => _firestore.collection('pomodoro_sessions');

  // ==================== TodoList CRUD ====================

  Future<TodoList> createTodoList(TodoList todoList) async {
    final docRef = await _todoListsCollection.add({
      ...todoList.toFirestore(),
      'userId': _userId,
    });
    return TodoList(
      id: docRef.id,
      name: todoList.name,
      description: todoList.description,
      color: todoList.color,
    );
  }

  Future<List<TodoList>> readAllTodoLists() async {
    final snapshot = await _todoListsCollection
        .where('userId', isEqualTo: _userId)
        .get();
    return snapshot.docs.map((doc) => TodoList.fromFirestore(doc)).toList();
  }

  Future<void> updateTodoList(TodoList todoList) async {
    await _todoListsCollection.doc(todoList.id).update({
      'name': todoList.name,
      'description': todoList.description,
      'color': todoList.color,
    });
  }

  Future<void> deleteTodoList(String id) async {
    // Delete all todos in this list first
    final todosSnapshot = await _todosCollection
        .where('listId', isEqualTo: id)
        .get();
    
    final batch = _firestore.batch();
    for (var doc in todosSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete the list
    batch.delete(_todoListsCollection.doc(id));
    await batch.commit();
  }

  // ==================== Todo CRUD ====================

  Future<Todo> createTodo(Todo todo) async {
    final docRef = await _todosCollection.add({
      ...todo.toFirestore(),
      'userId': _userId,
    });
    return todo.copyWith(id: docRef.id);
  }

  Future<List<Todo>> readAllTodos() async {
    final snapshot = await _todosCollection
        .where('userId', isEqualTo: _userId)
        .get();
    return snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList();
  }

  Future<List<Todo>> readTodosForList(String listId) async {
    final snapshot = await _todosCollection
        .where('listId', isEqualTo: listId)
        .get();
    return snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList();
  }

  Future<List<Todo>> readFavoriteTodos() async {
    final snapshot = await _todosCollection
        .where('userId', isEqualTo: _userId)
        .where('isFavorite', isEqualTo: true)
        .get();
    return snapshot.docs.map((doc) => Todo.fromFirestore(doc)).toList();
  }

  Future<List<Todo>> readTodosForToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final snapshot = await _todosCollection
        .where('userId', isEqualTo: _userId)
        .get();

    return snapshot.docs
        .map((doc) => Todo.fromFirestore(doc))
        .where((todo) {
          if (todo.dueDate == null) return false;
          return todo.dueDate!.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
              todo.dueDate!.isBefore(endOfDay.add(const Duration(seconds: 1)));
        })
        .toList();
  }

  Future<List<Todo>> readTodosByTag(String tagId) async {
    final allTodos = await readAllTodos();
    return allTodos.where((todo) => todo.tags.any((t) => t.id == tagId)).toList();
  }

  Future<void> updateTodo(Todo todo) async {
    await _todosCollection.doc(todo.id).update({
      'title': todo.title,
      'note': todo.note,
      'dueDate': todo.dueDate?.toIso8601String(),
      'priority': todo.priority.index,
      'isCompleted': todo.isCompleted,
      'isFavorite': todo.isFavorite,
      'subtasks': todo.subtasks.map((s) => s.toMap()).toList(),
      'tags': todo.tags.map((t) => t.toMap()).toList(),
      'recurrence': todo.recurrence.toMap(),
      'completedAt': todo.completedAt?.toIso8601String(),
      'order': todo.order,
      'pomodoroSessions': todo.pomodoroSessions,
    });
  }

  Future<void> updateTodoOrder(String todoId, int order) async {
    await _todosCollection.doc(todoId).update({'order': order});
  }

  Future<void> deleteTodo(String id) async {
    await _todosCollection.doc(id).delete();
  }

  // ==================== Event CRUD ====================

  Future<Event> createEvent(Event event) async {
    final docRef = await _eventsCollection.add({
      ...event.toFirestore(),
      'userId': _userId,
    });
    // Return the event with the generated ID
    return event.copyWith(id: docRef.id);
  }

  Future<List<Event>> readAllEvents() async {
    final snapshot = await _eventsCollection
        .where('userId', isEqualTo: _userId)
        .get();
    return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
  }

  Future<List<Event>> readEventsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Get all user's events and filter locally (Firestore doesn't support multiple inequality filters)
    final snapshot = await _eventsCollection
        .where('userId', isEqualTo: _userId)
        .get();
    
    return snapshot.docs
        .map((doc) => Event.fromFirestore(doc))
        .where((event) => 
            event.startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            event.startTime.isBefore(endOfDay.add(const Duration(seconds: 1))))
        .toList();
  }

  Future<void> updateEvent(Event event) async {
    await _eventsCollection.doc(event.id).update({
      'title': event.title,
      'description': event.description,
      'startTime': event.startTime.toIso8601String(),
      'endTime': event.endTime.toIso8601String(),
      'location': event.location,
      'isCompleted': event.isCompleted,
    });
  }

  Future<void> deleteEvent(String id) async {
    await _eventsCollection.doc(id).delete();
  }

  // ==================== Tag CRUD ====================

  Future<Tag> createTag(Tag tag) async {
    final docRef = await _tagsCollection.add({
      ...tag.toFirestore(),
      'userId': _userId,
    });
    return Tag(
      id: docRef.id,
      name: tag.name,
      color: tag.color,
    );
  }

  Future<List<Tag>> readAllTags() async {
    final snapshot = await _tagsCollection
        .where('userId', isEqualTo: _userId)
        .get();
    return snapshot.docs.map((doc) => Tag.fromFirestore(doc)).toList();
  }

  Future<void> updateTag(Tag tag) async {
    await _tagsCollection.doc(tag.id).update({
      'name': tag.name,
      'color': tag.color,
    });
  }

  Future<void> deleteTag(String id) async {
    await _tagsCollection.doc(id).delete();
  }

  // ==================== User Settings CRUD ====================

  Future<UserSettings> getUserSettings() async {
    final docRef = _userSettingsCollection.doc(_userId);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      // Create default settings
      final defaultSettings = UserSettings(id: _userId);
      await docRef.set(defaultSettings.toFirestore());
      return defaultSettings;
    }
    
    return UserSettings.fromFirestore(doc);
  }

  Future<void> updateUserSettings(UserSettings settings) async {
    await _userSettingsCollection.doc(_userId).set(
      settings.toFirestore(),
      SetOptions(merge: true),
    );
  }

  // ==================== Pomodoro Session CRUD ====================

  Future<PomodoroSession> createPomodoroSession(PomodoroSession session) async {
    final docRef = await _pomodoroSessionsCollection.add({
      ...session.toFirestore(),
      'userId': _userId,
    });
    return PomodoroSession(
      id: docRef.id,
      todoId: session.todoId,
      todoTitle: session.todoTitle,
      startTime: session.startTime,
      endTime: session.endTime,
      durationMinutes: session.durationMinutes,
      completed: session.completed,
    );
  }

  Future<List<PomodoroSession>> readAllPomodoroSessions() async {
    final snapshot = await _pomodoroSessionsCollection
        .where('userId', isEqualTo: _userId)
        .get();
    return snapshot.docs.map((doc) => PomodoroSession.fromFirestore(doc)).toList();
  }

  Future<List<PomodoroSession>> readPomodoroSessionsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _pomodoroSessionsCollection
        .where('userId', isEqualTo: _userId)
        .get();

    return snapshot.docs
        .map((doc) => PomodoroSession.fromFirestore(doc))
        .where((session) =>
            session.startTime.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
            session.startTime.isBefore(endOfDay.add(const Duration(seconds: 1))))
        .toList();
  }

  Future<int> getTotalPomodoroSessions() async {
    final sessions = await readAllPomodoroSessions();
    return sessions.where((s) => s.completed).length;
  }

  // ==================== Statistics ====================

  Future<Map<String, int>> getCompletionStatsForLastNDays(int days) async {
    final Map<String, int> stats = {};
    final now = DateTime.now();
    final todos = await readAllTodos();

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
      
      final completedOnDate = todos.where((todo) {
        if (!todo.isCompleted || todo.completedAt == null) return false;
        return todo.completedAt!.year == date.year &&
            todo.completedAt!.month == date.month &&
            todo.completedAt!.day == date.day;
      }).length;
      
      stats[dateKey] = completedOnDate;
    }

    return stats;
  }

  Future<Map<DateTime, int>> getMonthlyHeatmapData(int year, int month) async {
    final Map<DateTime, int> heatmap = {};
    final todos = await readAllTodos();

    for (var todo in todos) {
      if (todo.isCompleted && todo.completedAt != null) {
        if (todo.completedAt!.year == year && todo.completedAt!.month == month) {
          final date = DateTime(year, month, todo.completedAt!.day);
          heatmap[date] = (heatmap[date] ?? 0) + 1;
        }
      }
    }

    return heatmap;
  }

  Future<Map<int, int>> getProductivityByHour() async {
    final Map<int, int> hourlyStats = {};
    for (int i = 0; i < 24; i++) {
      hourlyStats[i] = 0;
    }

    final todos = await readAllTodos();
    for (var todo in todos) {
      if (todo.isCompleted && todo.completedAt != null) {
        final hour = todo.completedAt!.hour;
        hourlyStats[hour] = hourlyStats[hour]! + 1;
      }
    }

    return hourlyStats;
  }
}
