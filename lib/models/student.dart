// lib/models/student.dart
class Student {
  final String id;
  final String name;
  final String riwaya;
  final String sura;
  final String ayah;
  final DateTime timestamp;
  final String? groupId;

  Student({
    required this.id,
    required this.name,
    required this.riwaya,
    required this.sura,
    required this.ayah,
    required this.timestamp,
    this.groupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'riwaya': riwaya,
      'sura': sura,
      'ayah': ayah,
      'timestamp': timestamp.toIso8601String(),
      'groupId': groupId,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      riwaya: map['riwaya'],
      sura: map['sura'],
      ayah: map['ayah'],
      timestamp: DateTime.parse(map['timestamp']),
      groupId: map['groupId'],
    );
  }
}