// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_student_tracker/providers/student_provider.dart';
import 'package:quran_student_tracker/screens/student_form_screen.dart';
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
    await context.read<StudentProvider>().fetchStudents();
  }

  Future<void> _handleExport() async {
    if (!mounted) return;
    await DataExportImport.exportToJson(context);
    if (!mounted) return;
    context.read<StudentProvider>().fetchStudents();
  }

  Future<void> _handleImport() async {
    if (!mounted) return;
    await DataExportImport.importFromJson(context);
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
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.file_upload, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(local.translate('export')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.file_download, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(local.translate('import')),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                if (mounted) {
                  context.read<StudentProvider>().searchStudents(query);
                }
              },
              decoration: InputDecoration(
                hintText: local.translate('search'),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<StudentProvider>(
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(local.translate('add_recitation')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}