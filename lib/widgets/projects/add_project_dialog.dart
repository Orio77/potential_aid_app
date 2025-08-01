import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:time_machine/time_machine.dart';

/// Dialog for creating new projects.
///
/// This widget provides a form for users to input project details including
/// name, deadline, and optional start date. It handles validation, date picking,
/// and project creation with proper error handling and loading states.
class AddProjectDialog extends ConsumerStatefulWidget {
  const AddProjectDialog({super.key});

  @override
  ConsumerState<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends ConsumerState<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _deadline;
  DateTime _startDate = Instant.now().inUtc().toDateTimeUtc();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: Instant.now().inUtc().toDateTimeUtc().add(
        const Duration(days: 30),
      ),
      firstDate: Instant.now().inUtc().toDateTimeUtc(),
      lastDate: Instant.now().inUtc().toDateTimeUtc().add(
        const Duration(days: 365),
      ),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: Instant.now().inUtc().toDateTimeUtc().subtract(
        const Duration(days: 365),
      ),
      lastDate: Instant.now().inUtc().toDateTimeUtc().add(
        const Duration(days: 365),
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate() || _deadline == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(projectsNotifierProvider.notifier)
          .addProject(_nameController.text, _startDate, _deadline!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating project: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                hintText: 'Enter project name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a project name';
                }
                if (value.trim().length < 3) {
                  return 'Project name must be at least 3 characters';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectStartDate,
                    child: Text(
                      'Start: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectDeadline,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _deadline == null ? Colors.red : Colors.grey,
                      ),
                    ),
                    child: Text(
                      _deadline == null
                          ? 'Select Deadline *'
                          : 'Due: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                      style: TextStyle(
                        color: _deadline == null ? Colors.red : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_deadline == null)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Deadline is required',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProject,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
