// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_student_tracker/providers/student_provider.dart';
import 'package:quran_student_tracker/screens/student_form_screen.dart';
import 'package:quran_student_tracker/screens/groups_screen.dart';
import 'package:quran_student_tracker/widgets/student_card.dart';
import 'package:quran_student_tracker/l10n/app_localizations.dart';
import 'package:quran_student_tracker/helpers/data_export_import.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final provider = context.read<StudentProvider>();
    await provider.fetchGroups();
    await provider.fetchStudents();
  }

  Future<void> _handleExport() async {
    await DataExportImport.exportToJson(context);
    if (!mounted) return;
    context.read<StudentProvider>().fetchStudents();
  }

  Future<void> _handleImport() async {
    await DataExportImport.importFromJson(context);
    if (!mounted) return;
    context.read<StudentProvider>().fetchStudents();
  }

  Future<void> _navigateToGroups() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupsScreen()),
    );
    // After returning from Groups screen, refresh data
    if (!mounted) return;
    context.read<StudentProvider>().fetchStudents();
  }

  Future<void> _navigateToAddStudent() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentFormScreen()),
    );
    // After returning from Add Student screen, refresh data
    if (!mounted) return;
    context.read<StudentProvider>().fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(local.translate('app_title')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_work),
            onPressed: _navigateToGroups,
            tooltip: 'إدارة المجموعات',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'export':
                  await _handleExport();
                  break;
                case 'import':
                  await _handleImport();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_upload, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('تصدير البيانات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: Colors.green),
                    SizedBox(width: 8),
                    Text('استيراد البيانات'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<StudentProvider>().searchStudents(query);
              },
              decoration: InputDecoration(
                hintText: local.translate('search'),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Group tabs
          Consumer<StudentProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildGroupTab(
                      name: 'الكل',
                      isSelected: provider.selectedGroupId == null,
                      onTap: () => provider.selectGroup(null),
                    ),
                    const SizedBox(width: 8),
                    ...provider.groups.map((group) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildGroupTab(
                        name: group.name,
                        color: group.colorValue,
                        isSelected: provider.selectedGroupId == group.id,
                        onTap: () => provider.selectGroup(group.id),
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          // Student list
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.students.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          local.translate('no_records'),
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: provider.students.length,
                  itemBuilder: (context, index) {
                    return StudentCard(student: provider.students[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddStudent,
        icon: const Icon(Icons.add),
        label: Text(local.translate('add_recitation')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildGroupTab({
    required String name,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (color ?? Theme.of(context).colorScheme.primary).withAlpha(26)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? (color ?? Theme.of(context).colorScheme.primary)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              name,
              style: TextStyle(
                color: isSelected 
                    ? (color ?? Theme.of(context).colorScheme.primary)
                    : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}