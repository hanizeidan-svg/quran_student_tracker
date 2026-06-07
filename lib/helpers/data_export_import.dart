// lib/helpers/data_export_import.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_student_tracker/helpers/database_helper.dart';

class DataExportImport {
  // Export all students to JSON and share/save
  static Future<void> exportToJson(BuildContext context) async {
    try {
      final students = await DatabaseHelper.instance.getAllStudents();
      
      if (!context.mounted) return;
      
      if (students.isEmpty) {
        _showSnackBar(context, 'لا يوجد طلاب للتصدير', isError: true);
        return;
      }

      final exportData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'total_students': students.length,
        'students': students,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      
      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final fileName = 'quran_students_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString, encoding: utf8);

      if (!context.mounted) return;
      _showExportOptionsDialog(context, file);
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'خطأ في التصدير: $e', isError: true);
      }
    }
  }

  // Show export options dialog
  static void _showExportOptionsDialog(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصدير البيانات'),
        content: const Text('تم تجهيز ملف النسخ الاحتياطي. اختر طريقة التصدير:'),
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

  // Import students from JSON file
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
      int importCount = 0;
      int skipCount = 0;

      if (!context.mounted) return;

      // Show confirmation dialog
      bool? confirmed = await _showImportConfirmationDialog(context, studentsList.length);
      if (confirmed != true) return;

      // Import each student
      for (var studentData in studentsList) {
        try {
          if (studentData is Map<String, dynamic>) {
            // Generate new ID to avoid conflicts
            studentData['id'] = '${studentData['id']}_imported_${DateTime.now().millisecondsSinceEpoch}';
            
            await DatabaseHelper.instance.insertStudent(studentData);
            importCount++;
          }
        } catch (e) {
          skipCount++;
          debugPrint('Error importing student: $e');
        }
      }

      if (context.mounted) {
        _showSnackBar(
          context,
          'تم استيراد $importCount طالب${skipCount > 0 ? ' (تم تخطي $skipCount)' : ''}',
          isError: skipCount > 0,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'خطأ في الاستيراد: $e', isError: true);
      }
    }
  }

  // Show import confirmation dialog
  static Future<bool?> _showImportConfirmationDialog(BuildContext context, int studentCount) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الاستيراد'),
        content: Text('سيتم استيراد $studentCount طالب. هل تريد المتابعة؟'),
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