// lib/screens/student_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:quran_student_tracker/models/student.dart';
import 'package:quran_student_tracker/providers/student_provider.dart';
import 'package:quran_student_tracker/l10n/app_localizations.dart';

class StudentFormScreen extends StatefulWidget {
  final Student? student;
  const StudentFormScreen({super.key, this.student});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _riwayaController;
  late TextEditingController _suraController;
  late TextEditingController _ayahController;

  bool get isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _riwayaController =
        TextEditingController(text: widget.student?.riwaya ?? 'حفص عن عاصم');
    _suraController = TextEditingController(text: widget.student?.sura ?? '');
    _ayahController = TextEditingController(text: widget.student?.ayah ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _riwayaController.dispose();
    _suraController.dispose();
    _ayahController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<StudentProvider>();
      final local = AppLocalizations.of(context);
      final student = Student(
        id: widget.student?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        riwaya: _riwayaController.text.trim(),
        sura: _suraController.text.trim(),
        ayah: _ayahController.text.trim(),
        timestamp: widget.student?.timestamp ?? DateTime.now(),
      );

      if (isEditing) {
        await provider.updateStudent(student);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(local.translate('record_updated'))),
          );
        }
      } else {
        await provider.addStudent(student);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(local.translate('record_added'))),
          );
        }
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEditing ? local.translate('edit_recitation') : local.translate('add_recitation')),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: local.translate('student_name'),
                icon: Icons.person,
                validator: (value) =>
                    value?.isEmpty ?? true ? local.translate('required_field') : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _riwayaController,
                label: local.translate('riwaya'),
                icon: Icons.menu_book,
                validator: (value) =>
                    value?.isEmpty ?? true ? local.translate('required_field') : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _suraController,
                      label: local.translate('sura'),
                      icon: Icons.book,
                      validator: (value) =>
                          value?.isEmpty ?? true ? local.translate('required_field') : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _ayahController,
                      label: local.translate('ayah'),
                      icon: Icons.format_list_numbered,
                      validator: (value) =>
                          value?.isEmpty ?? true ? local.translate('required_field') : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveForm,
                icon: const Icon(Icons.save),
                label: Text(local.translate('save')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
      textInputAction: TextInputAction.next,
    );
  }
}