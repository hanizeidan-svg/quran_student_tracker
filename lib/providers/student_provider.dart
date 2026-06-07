// lib/providers/student_provider.dart
import 'package:flutter/foundation.dart';
import 'package:quran_student_tracker/models/student.dart';
import 'package:quran_student_tracker/helpers/database_helper.dart';

class StudentProvider with ChangeNotifier {
  List<Student> _students = [];
  bool _isLoading = false;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;

  Future<void> fetchStudents() async {
    _isLoading = true;
    notifyListeners();
    final data = await DatabaseHelper.instance.getAllStudents();
    _students = data.map((map) => Student.fromMap(map)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchStudents(String query) async {
    _isLoading = true;
    notifyListeners();
    if (query.isEmpty) {
      await fetchStudents();
    } else {
      final data = await DatabaseHelper.instance.searchStudents(query);
      _students = data.map((map) => Student.fromMap(map)).toList();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addStudent(Student student) async {
    await DatabaseHelper.instance.insertStudent(student.toMap());
    await fetchStudents();
  }

  Future<void> updateStudent(Student student) async {
    await DatabaseHelper.instance.updateStudent(student.toMap());
    await fetchStudents();
  }

  Future<void> deleteStudent(String id) async {
    await DatabaseHelper.instance.deleteStudent(id);
    await fetchStudents();
  }
}