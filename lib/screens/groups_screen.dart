// lib/screens/groups_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:quran_student_tracker/models/student_group.dart';
import 'package:quran_student_tracker/providers/student_provider.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المجموعات'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_work, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد مجموعات',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أنشئ مجموعة لتنظيم طلابك',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.groups.length,
            itemBuilder: (context, index) {
              final group = provider.groups[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: group.colorValue,
                    child: const Icon(Icons.group, color: Colors.white),
                  ),
                  title: Text(
                    group.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('أنشئت في ${group.createdAt.toString().substring(0, 10)}'),
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showGroupDialog(context, group: group);
                      } else if (value == 'delete') {
                        _showDeleteConfirmDialog(context, group);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('مجموعة جديدة'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showGroupDialog(BuildContext context, {StudentGroup? group}) {
    final nameController = TextEditingController(text: group?.name ?? '');
    Color selectedColor = group?.colorValue ?? const Color(0xFF1B5E4A);
    final isEditing = group != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'تعديل المجموعة' : 'مجموعة جديدة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المجموعة',
                    prefixIcon: Icon(Icons.group),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text('اختر لون المجموعة:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    Colors.blue,
                    Colors.red,
                    Colors.green,
                    Colors.orange,
                    Colors.purple,
                    Colors.teal,
                    Colors.pink,
                    Colors.indigo,
                    Colors.brown,
                    const Color(0xFF1B5E4A),
                  ].map((color) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final provider = context.read<StudentProvider>();
                  final newGroup = StudentGroup(
                    id: group?.id ?? const Uuid().v4(),
                    name: nameController.text.trim(),
                    color: selectedColor.toARGB32(),
                    createdAt: group?.createdAt ?? DateTime.now(),
                  );
                  
                  if (isEditing) {
                    provider.updateGroup(newGroup);
                  } else {
                    provider.addGroup(newGroup);
                  }
                  
                  Navigator.pop(ctx);
                }
              },
              child: Text(isEditing ? 'تحديث' : 'إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, StudentGroup group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المجموعة'),
        content: Text('هل أنت متأكد من حذف مجموعة "${group.name}"؟ سيتم إزالة جميع الطلاب من هذه المجموعة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              context.read<StudentProvider>().deleteGroup(group.id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}