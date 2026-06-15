// lib/screens/student_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:quran_student_tracker/models/student.dart';
import 'package:quran_student_tracker/providers/student_provider.dart';
import 'package:quran_student_tracker/l10n/app_localizations.dart';
import 'package:quran_student_tracker/widgets/assign_group_dialog.dart';

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
  late DateTime _selectedDateTime;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  String? _selectedGroupId;
  String? _selectedGroupName;

  bool get isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student?.name ?? '');
    _riwayaController =
        TextEditingController(text: widget.student?.riwaya ?? 'حفص عن عاصم');
    _suraController = TextEditingController(text: widget.student?.sura ?? '');
    _ayahController = TextEditingController(text: widget.student?.ayah ?? '');
    
    // Preserve the groupId from the existing student
    _selectedGroupId = widget.student?.groupId;
    
    // Initialize with existing timestamp or current time
    _selectedDateTime = widget.student?.timestamp ?? DateTime.now();
    
    // Format controllers for display
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('hh:mm a');
    _dateController = TextEditingController(text: dateFormat.format(_selectedDateTime));
    _timeController = TextEditingController(text: timeFormat.format(_selectedDateTime));
    
    // Get group name if student has a group
    if (_selectedGroupId != null) {
      _loadGroupName();
    }
  }

  Future<void> _loadGroupName() async {
    // We'll get the group name from the provider after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedGroupId != null) {
        final provider = context.read<StudentProvider>();
        final group = provider.groups.where((g) => g.id == _selectedGroupId).firstOrNull;
        if (group != null) {
          setState(() {
            _selectedGroupName = group.name;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _riwayaController.dispose();
    _suraController.dispose();
    _ayahController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'اختر تاريخ التسميع',
      cancelText: 'إلغاء',
      confirmText: 'تم',
      fieldLabelText: 'التاريخ',
    );
    if (picked != null && picked != _selectedDateTime) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
        final dateFormat = DateFormat('yyyy/MM/dd');
        _dateController.text = dateFormat.format(_selectedDateTime);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      helpText: 'اختر وقت التسميع',
      cancelText: 'إلغاء',
      confirmText: 'تم',
      hourLabelText: 'الساعة',
      minuteLabelText: 'الدقيقة',
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
        final timeFormat = DateFormat('hh:mm a');
        _timeController.text = timeFormat.format(_selectedDateTime);
      });
    }
  }

  Future<void> _showGroupSelection() async {
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AssignGroupDialog(
        studentId: widget.student?.id ?? '',
        currentGroupId: _selectedGroupId,
      ),
    );
    
    if (result != null || result == null) {
      // Refresh the group ID after dialog closes
      if (mounted) {
        final provider = context.read<StudentProvider>();
        // If editing, get the latest groupId from provider
        if (isEditing && widget.student != null) {
          final updatedStudent = provider.students
              .where((s) => s.id == widget.student!.id)
              .firstOrNull;
          setState(() {
            _selectedGroupId = updatedStudent?.groupId;
            if (_selectedGroupId != null) {
              final group = provider.groups
                  .where((g) => g.id == _selectedGroupId)
                  .firstOrNull;
              _selectedGroupName = group?.name;
            } else {
              _selectedGroupName = null;
            }
          });
        }
      }
    }
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
        timestamp: _selectedDateTime,
        groupId: _selectedGroupId, // Preserve the group ID
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
    final provider = context.read<StudentProvider>();
    
    // Get group name for display
    if (_selectedGroupId != null && _selectedGroupName == null) {
      final group = provider.groups
          .where((g) => g.id == _selectedGroupId)
          .firstOrNull;
      if (group != null) {
        _selectedGroupName = group.name;
      }
    }
    
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
              const SizedBox(height: 16),
              // Date and Time Pickers
              Text(
                'وقت التسميع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeField(
                      controller: _dateController,
                      label: 'التاريخ',
                      icon: Icons.calendar_today,
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateTimeField(
                      controller: _timeController,
                      label: 'الوقت',
                      icon: Icons.access_time,
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              // Show "Now" button to set current time
              if (isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDateTime = DateTime.now();
                        final dateFormat = DateFormat('yyyy/MM/dd');
                        final timeFormat = DateFormat('hh:mm a');
                        _dateController.text = dateFormat.format(_selectedDateTime);
                        _timeController.text = timeFormat.format(_selectedDateTime);
                      });
                    },
                    icon: const Icon(Icons.update, size: 18),
                    label: const Text('تحديث إلى الوقت الحالي'),
                  ),
                ),
              const SizedBox(height: 16),
              // Group selection
              Text(
                'المجموعة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showGroupSelection,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.group_work,
                        color: _selectedGroupId != null 
                            ? (provider.groups
                                .where((g) => g.id == _selectedGroupId)
                                .firstOrNull
                                ?.colorValue ?? Colors.grey)
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedGroupName ?? 'بدون مجموعة',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedGroupId != null 
                                ? Colors.black87 
                                : Colors.grey.shade600,
                            fontWeight: _selectedGroupId != null 
                                ? FontWeight.w500 
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
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

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      validator: (value) =>
          value?.isEmpty ?? true ? 'مطلوب' : null,
    );
  }
}