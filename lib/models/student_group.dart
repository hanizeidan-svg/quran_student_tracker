// lib/models/student_group.dart
import 'dart:ui';

class StudentGroup {
  final String id;
  final String name;
  final int color;
  final DateTime createdAt;

  StudentGroup({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  Color get colorValue => Color(color);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudentGroup.fromMap(Map<String, dynamic> map) {
    return StudentGroup(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}