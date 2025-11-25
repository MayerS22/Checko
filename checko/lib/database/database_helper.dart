import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';

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
      version: 1,
      onCreate: _createDB,
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

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
