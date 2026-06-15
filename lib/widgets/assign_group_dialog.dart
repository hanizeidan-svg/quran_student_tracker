// lib/widgets/assign_group_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_student_tracker/providers/student_provider.dart';

class AssignGroupDialog extends StatefulWidget {
  final String studentId;
  final String? currentGroupId;

  const AssignGroupDialog({
    super.key,
    required this.studentId,
    this.currentGroupId,
  });

  @override
  State<AssignGroupDialog> createState() => _AssignGroupDialogState();
}

class _AssignGroupDialogState extends State<AssignGroupDialog> {
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.currentGroupId;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          title: const Text('تحديد المجموعة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "No Group" option
                _buildRadioTile<String?>(
                  title: 'بدون مجموعة',
                  value: null,
                ),
                // Divider
                if (provider.groups.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(),
                  ),
                // Group options
                ...provider.groups.map((group) => _buildRadioTile<String>(
                  title: group.name,
                  value: group.id,
                  color: group.colorValue,
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.assignStudentToGroup(
                  widget.studentId,
                  _selectedGroupId,
                );
                Navigator.pop(context, _selectedGroupId);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required T value,
    Color? color,
  }) {
    final isSelected = _selectedGroupId == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGroupId = value as String?;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? Theme.of(context).colorScheme.primary).withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (color ?? Theme.of(context).colorScheme.primary)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Custom radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? (color ?? Theme.of(context).colorScheme.primary)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color ?? Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey.shade700,
                ),
              ),
            ),
            // Color indicator for groups
            if (color != null)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(77),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}