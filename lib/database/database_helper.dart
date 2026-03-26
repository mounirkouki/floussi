import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/payment.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Named constructor for subclassing in tests only.
  @visibleForTesting
  DatabaseHelper.testOnly();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('floussi.db');
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

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        total_budget REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        agreed_amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        project_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');
  }

  // ─── Projects ────────────────────────────────────────────────────────────

  Future<List<Project>> getProjects() async {
    final db = await database;
    final result = await db.query('projects', orderBy: 'created_at DESC');
    return result.map(Project.fromMap).toList();
  }

  Future<Project?> getProject(String id) async {
    final db = await database;
    final result =
        await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Project.fromMap(result.first);
  }

  Future<void> insertProject(Project project) async {
    final db = await database;
    await db.insert('projects', project.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProject(Project project) async {
    final db = await database;
    await db.update('projects', project.toMap(),
        where: 'id = ?', whereArgs: [project.id]);
  }

  Future<void> deleteProject(String id) async {
    final db = await database;
    // Tasks and payments are deleted via ON DELETE CASCADE
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Tasks ────────────────────────────────────────────────────────────────

  Future<List<Task>> getTasksForProject(String projectId) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at ASC',
    );
    return result.map(Task.fromMap).toList();
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTask(Task task) async {
    final db = await database;
    await db.update('tasks', task.toMap(),
        where: 'id = ?', whereArgs: [task.id]);
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Payments ─────────────────────────────────────────────────────────────

  Future<List<Payment>> getPaymentsForTask(String taskId) async {
    final db = await database;
    final result = await db.query(
      'payments',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'date DESC',
    );
    return result.map(Payment.fromMap).toList();
  }

  Future<List<Payment>> getPaymentsForProject(String projectId) async {
    final db = await database;
    final result = await db.query(
      'payments',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'date DESC',
    );
    return result.map(Payment.fromMap).toList();
  }

  Future<void> insertPayment(Payment payment) async {
    final db = await database;
    await db.insert('payments', payment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePayment(String id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
