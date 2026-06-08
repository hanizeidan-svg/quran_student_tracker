// lib/providers/student_provider.dart
import 'package:flutter/foundation.dart';
import 'package:quran_student_tracker/models/student.dart';
import 'package:quran_student_tracker/models/student_group.dart';
import 'package:quran_student_tracker/helpers/database_helper.dart';

class StudentProvider with ChangeNotifier {
  List<Student> _students = [];
  List<StudentGroup> _groups = [];
  String? _selectedGroupId;
  bool _isLoading = false;

  List<Student> get students => _students;
  List<StudentGroup> get groups => _groups;
  String? get selectedGroupId => _selectedGroupId;
  bool get isLoading => _isLoading;

  Future<void> fetchStudents() async {
    _isLoading = true;
    notifyListeners();
    
    final data = await DatabaseHelper.instance.getStudentsByGroup(_selectedGroupId);
    _students = data.map((map) => Student.fromMap(map)).toList();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGroups() async {
    final data = await DatabaseHelper.instance.getAllGroups();
    _groups = data.map((map) => StudentGroup.fromMap(map)).toList();
    notifyListeners();
  }

  void selectGroup(String? groupId) {
    _selectedGroupId = groupId;
    fetchStudents();
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

  Future<void> addGroup(StudentGroup group) async {
    await DatabaseHelper.instance.insertGroup(group.toMap());
    await fetchGroups();
  }

  Future<void> updateGroup(StudentGroup group) async {
    await DatabaseHelper.instance.updateGroup(group.toMap());
    await fetchGroups();
  }

  Future<void> deleteGroup(String id) async {
    await DatabaseHelper.instance.deleteGroup(id);
    if (_selectedGroupId == id) {
      _selectedGroupId = null;
    }
    await fetchGroups();
    await fetchStudents();
  }

  Future<void> assignStudentToGroup(String studentId, String? groupId) async {
    await DatabaseHelper.instance.assignStudentToGroup(studentId, groupId);
    await fetchStudents();
  }

  int getStudentCountForGroup(String groupId) {
    // This would require a database query, but for simplicity:
    return _students.where((s) => s.groupId == groupId).length;
  }
}