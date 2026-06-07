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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        riwaya TEXT NOT NULL,
        sura TEXT NOT NULL,
        ayah TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertStudent(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('students', row);
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    final db = await instance.database;
    return await db.query('students', orderBy: 'timestamp DESC');
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
}
