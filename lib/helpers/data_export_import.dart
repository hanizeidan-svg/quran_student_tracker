// lib/helpers/data_export_import.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_student_tracker/helpers/database_helper.dart';

class DataExportImport {
  // Export all students and groups to JSON
  static Future<void> exportToJson(BuildContext context) async {
    try {
      final students = await DatabaseHelper.instance.getAllStudents();
      final groups = await DatabaseHelper.instance.getAllGroups();
      
      if (!context.mounted) return;
      
      if (students.isEmpty && groups.isEmpty) {
        _showSnackBar(context, 'لا يوجد بيانات للتصدير', isError: true);
        return;
      }

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'total_students': students.length,
        'total_groups': groups.length,
        'students': students,
        'groups': groups,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final fileName = 'quran_students_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString, encoding: utf8);

      if (!context.mounted) return;
      _showExportOptionsDialog(context, file, students.length, groups.length);
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'خطأ في التصدير: $e', isError: true);
      }
    }
  }

  // Show export options dialog
  static void _showExportOptionsDialog(
    BuildContext context, 
    File file, 
    int studentCount, 
    int groupCount,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تم تجهيز ملف النسخ الاحتياطي.'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.people, 'عدد الطلاب', '$studentCount طالب'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.group_work, 'عدد المجموعات', '$groupCount مجموعة'),
            const SizedBox(height: 12),
            const Text('اختر طريقة التصدير:'),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _shareFile(context, file);
            },
            icon: const Icon(Icons.share),
            label: const Text('مشاركة'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveToDevice(context, file);
            },
            icon: const Icon(Icons.save_alt),
            label: const Text('حفظ في الجهاز'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  // Share file using share_plus
  static Future<void> _shareFile(BuildContext context, File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'نسخة احتياطية لبيانات طلاب القرآن',
      );
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'خطأ في المشاركة: $e', isError: true);
      }
    }
  }

  // Save file to device using file picker
  static Future<void> _saveToDevice(BuildContext context, File file) async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'حفظ ملف النسخ الاحتياطي',
        fileName: 'quran_students_backup.json',
        type: FileType.any,
      );

      if (outputFile != null) {
        await file.copy(outputFile);
        if (context.mounted) {
          _showSnackBar(context, 'تم حفظ الملف بنجاح');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'خطأ في الحفظ: $e', isError: true);
      }
    }
  }

  // Import students and groups from JSON file
  static Future<void> importFromJson(BuildContext context) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;
      
      if (!context.mounted) return;

      final file = File(result.files.single.path!);
      
      // Read and parse JSON
      final jsonString = await file.readAsString(encoding: utf8);
      final Map<String, dynamic> importData = json.decode(jsonString);

      // Validate data structure
      if (!importData.containsKey('students') || importData['students'] is! List) {
        if (context.mounted) {
          _showSnackBar(context, 'ملف غير صالح: تنسيق البيانات غير صحيح', isError: true);
        }
        return;
      }

      final List<dynamic> studentsList = importData['students'];
      final List<dynamic>? groupsList = importData['groups'] is List 
          ? importData['groups'] as List<dynamic>
          : null;
      
      int importedStudents = 0;
      int skippedStudents = 0;
      int importedGroups = 0;
      int skippedGroups = 0;
      
      // Map to store old group IDs to new group IDs
      final Map<String, String> groupIdMapping = {};

      if (!context.mounted) return;

      // Show confirmation dialog
      bool? confirmed = await _showImportConfirmationDialog(
        context, 
        studentsList.length,
        groupsList?.length ?? 0,
      );
      if (confirmed != true) return;

      // Import groups first
      if (groupsList != null && groupsList.isNotEmpty) {
        for (var groupData in groupsList) {
          try {
            if (groupData is Map<String, dynamic>) {
              final oldGroupId = groupData['id'] as String;
              // Generate new ID to avoid conflicts with existing groups
              final newGroupId = '${oldGroupId}_imported_${DateTime.now().millisecondsSinceEpoch}';
              
              // Store the mapping
              groupIdMapping[oldGroupId] = newGroupId;
              
              // Create new group with new ID
              final newGroup = {
                'id': newGroupId,
                'name': groupData['name'],
                'color': groupData['color'],
                'createdAt': groupData['createdAt'] ?? DateTime.now().toIso8601String(),
              };
              
              await DatabaseHelper.instance.insertGroup(newGroup);
              importedGroups++;
            }
          } catch (e) {
            skippedGroups++;
            debugPrint('Error importing group: $e');
          }
        }
      }

      // Import students with updated group IDs
      for (var studentData in studentsList) {
        try {
          if (studentData is Map<String, dynamic>) {
            // Generate new ID to avoid conflicts
            studentData['id'] = '${studentData['id']}_imported_${DateTime.now().millisecondsSinceEpoch}';
            
            // Update groupId if it exists
            if (studentData['groupId'] != null && groupIdMapping.containsKey(studentData['groupId'])) {
              studentData['groupId'] = groupIdMapping[studentData['groupId']];
            }
            
            await DatabaseHelper.instance.insertStudent(studentData);
            importedStudents++;
          }
        } catch (e) {
          skippedStudents++;
          debugPrint('Error importing student: $e');
        }
      }

      // Refresh the provider data
      if (context.mounted) {
        // Build result message
        String message = 'تم استيراد $importedStudents طالب';
        if (importedGroups > 0) {
          message += ' و $importedGroups مجموعة';
        }
        if (skippedStudents > 0) {
          message += ' (تم تخطي $skippedStudents طالب)';
        }
        if (skippedGroups > 0) {
          message += ' (تم تخطي $skippedGroups مجموعة)';
        }
        
        _showSnackBar(
          context,
          message,
          isError: skippedStudents > 0 || skippedGroups > 0,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'خطأ في الاستيراد: $e', isError: true);
      }
    }
  }

  // Show import confirmation dialog
  static Future<bool?> _showImportConfirmationDialog(
    BuildContext context, 
    int studentCount,
    int groupCount,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الاستيراد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سيتم استيراد البيانات التالية:'),
            const SizedBox(height: 8),
            Text('• $studentCount طالب'),
            if (groupCount > 0) Text('• $groupCount مجموعة'),
            const SizedBox(height: 8),
            const Text('هل تريد المتابعة؟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('استيراد'),
          ),
        ],
      ),
    );
  }

  // Helper to show snackbar
  static void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
