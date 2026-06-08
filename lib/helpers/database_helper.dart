// lib/helpers/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quran_students.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        riwaya TEXT NOT NULL,
        sura TEXT NOT NULL,
        ayah TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        groupId TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE student_groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add groupId column to existing students table
      await db.execute('ALTER TABLE students ADD COLUMN groupId TEXT');
      
      // Create groups table
      await db.execute('''
        CREATE TABLE student_groups (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color INTEGER NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
  }

  // Student operations
  Future<int> insertStudent(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('students', row);
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final db = await instance.database;
    return await db.query('students', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getStudentsByGroup(String? groupId) async {
    final db = await instance.database;
    if (groupId == null) {
      // Get ungrouped students
      return await db.query('students', 
        where: 'groupId IS NULL',
        orderBy: 'timestamp DESC'
      );
    } else {
      return await db.query('students', 
        where: 'groupId = ?',
        whereArgs: [groupId],
        orderBy: 'timestamp DESC'
      );
    }
  }

  Future<int> updateStudent(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'students',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteStudent(String id) async {
    final db = await instance.database;
    return await db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchStudents(String query) async {
    final db = await instance.database;
    return await db.query(
      'students',
      where: 'name LIKE ? OR riwaya LIKE ? OR sura LIKE ? OR ayah LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
  }

  // Group operations
  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final db = await instance.database;
    return await db.query('student_groups', orderBy: 'createdAt DESC');
  }

  Future<int> insertGroup(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('student_groups', row);
  }

  Future<int> updateGroup(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'student_groups',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteGroup(String id) async {
    final db = await instance.database;
    // Remove group from all students in this group
    await db.update(
      'students',
      {'groupId': null},
      where: 'groupId = ?',
      whereArgs: [id],
    );
    // Delete the group
    return await db.delete(
      'student_groups',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> assignStudentToGroup(String studentId, String? groupId) async {
    final db = await instance.database;
    await db.update(
      'students',
      {'groupId': groupId},
      where: 'id = ?',
      whereArgs: [studentId],
    );
  }
}