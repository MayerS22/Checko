import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../models/event.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('checko.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const boolType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE todo_lists (
        id $idType,
        name $textType,
        description $textTypeNullable,
        color $integerType
      )
    ''');

    await db.execute('''
      CREATE TABLE todos (
        id $idType,
        listId $textType,
        title $textType,
        note $textTypeNullable,
        dueDate $textTypeNullable,
        priority $integerType,
        isCompleted $boolType,
        isFavorite $boolType,
        FOREIGN KEY (listId) REFERENCES todo_lists (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE events (
        id $idType,
        title $textType,
        description $textTypeNullable,
        startTime $textType,
        endTime $textType,
        location $textTypeNullable,
        isCompleted $boolType
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const textTypeNullable = 'TEXT';
      const boolType = 'INTEGER NOT NULL';

      await db.execute('''
        CREATE TABLE events (
          id $idType,
          title $textType,
          description $textTypeNullable,
          startTime $textType,
          endTime $textType,
          location $textTypeNullable,
          isCompleted $boolType
        )
      ''');
    }
  }

  // TodoList CRUD operations
  Future<TodoList> createTodoList(TodoList todoList) async {
    final db = await instance.database;
    await db.insert('todo_lists', todoList.toMap());
    return todoList;
  }

  Future<List<TodoList>> readAllTodoLists() async {
    final db = await instance.database;
    final result = await db.query('todo_lists');
    return result.map((json) => TodoList.fromMap(json)).toList();
  }

  Future<int> updateTodoList(TodoList todoList) async {
    final db = await instance.database;
    return db.update(
      'todo_lists',
      todoList.toMap(),
      where: 'id = ?',
      whereArgs: [todoList.id],
    );
  }

  Future<int> deleteTodoList(String id) async {
    final db = await instance.database;

    // Delete all todos in this list first
    await db.delete(
      'todos',
      where: 'listId = ?',
      whereArgs: [id],
    );

    // Then delete the list
    return await db.delete(
      'todo_lists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Todo CRUD operations
  Future<Todo> createTodo(Todo todo) async {
    final db = await instance.database;
    await db.insert('todos', todo.toMap());
    return todo;
  }

  Future<List<Todo>> readAllTodos() async {
    final db = await instance.database;
    final result = await db.query('todos');
    return result.map((json) => Todo.fromMap(json)).toList();
  }

  Future<List<Todo>> readTodosForList(String listId) async {
    final db = await instance.database;
    final result = await db.query(
      'todos',
      where: 'listId = ?',
      whereArgs: [listId],
    );
    return result.map((json) => Todo.fromMap(json)).toList();
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await instance.database;
    return db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> deleteTodo(String id) async {
    final db = await instance.database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Event CRUD operations
  Future<Event> createEvent(Event event) async {
    final db = await instance.database;
    await db.insert('events', event.toMap());
    return event;
  }

  Future<List<Event>> readAllEvents() async {
    final db = await instance.database;
    final result = await db.query('events');
    return result.map((json) => Event.fromMap(json)).toList();
  }

  Future<List<Event>> readEventsForDate(DateTime date) async {
    final db = await instance.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final result = await db.query(
      'events',
      where: 'startTime >= ? AND startTime <= ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return result.map((json) => Event.fromMap(json)).toList();
  }

  Future<int> updateEvent(Event event) async {
    final db = await instance.database;
    return db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(String id) async {
    final db = await instance.database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
