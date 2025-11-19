import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_intervals_notifier.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/providers/stats_provider.dart';
import 'package:potential_aid_app/utils/time_utils.dart';
import 'package:potential_aid_app/widgets/common/goal_progress_input.dart';

class AddProjectDialog extends ConsumerStatefulWidget {
  final int? categoryId;
  final ProjectData? projectData;
  const AddProjectDialog({super.key, this.categoryId, this.projectData});

  @override
  ConsumerState<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends ConsumerState<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _currentController = TextEditingController();
  final _endGoalController = TextEditingController();
  final _unitController = TextEditingController();
  late DateTime _startDate;
  late DateTime _deadline;
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isFormValid {
    return _projectNameController.text.trim().isNotEmpty &&
        _currentController.text.trim().isNotEmpty &&
        _endGoalController.text.trim().isNotEmpty &&
        _unitController.text.trim().isNotEmpty &&
        int.tryParse(_currentController.text) != null &&
        int.tryParse(_endGoalController.text) != null;
  }

  @override
  void initState() {
    final date = ref.read(dateNotifierProvider);
    _startDate = date.toDateTimeUnspecified();
    _deadline = date.toDateTimeUnspecified().add(Duration(days: 7));

    _projectNameController.addListener(_updateButtonState);
    _currentController.addListener(_updateButtonState);
    _endGoalController.addListener(_updateButtonState);
    _unitController.addListener(_updateButtonState);

    final projectData = widget.projectData;

    if (widget.projectData != null) {
      _projectNameController.text = projectData!.name;
      _currentController.text = projectData.current.toString();
      _endGoalController.text = projectData.goal.toString();
      _unitController.text = projectData.unit;
      _startDate = projectData.startDate;
      _deadline = projectData.deadline;
    }

    super.initState();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _currentController.dispose();
    _endGoalController.dispose();
    _unitController.dispose();

    _projectNameController.removeListener(_updateButtonState);
    _currentController.removeListener(_updateButtonState);
    _endGoalController.removeListener(_updateButtonState);
    _unitController.removeListener(_updateButtonState);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.read(dateNotifierProvider).toDateTimeUnspecified();

    return AlertDialog(
      title: Center(
        child: widget.projectData == null
            ? Text('Add New Project')
            : Text('Edit Project'),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _projectNameController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  labelText: 'Project name',
                  border: OutlineInputBorder(),
                ),
                validator: _validateProjectName,
                enabled: !_isLoading,
              ),

              const SizedBox(height: 16),

              GoalProgressInput(
                currentController: _currentController,
                endGoalController: _endGoalController,
                unitController: _unitController,
              ),

              const SizedBox(height: 16),

              if (widget.projectData != null) ...[
                IconButton(
                  onPressed: () async =>
                      _chooseNewProjectColor(context, ref, widget.projectData!),
                  icon: Icon(Icons.color_lens_rounded),
                ),
              ],

              const SizedBox(height: 16),

              Column(
                spacing: 6,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async =>
                            _selectDate(context, today, false),
                        label: Icon(Icons.calendar_today),
                      ),
                      Text(
                        'Start Date: ${TimeUtils.formatDateTime(_startDate)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 6,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async =>
                            _selectDate(context, today, true),
                        label: Icon(Icons.calendar_today),
                      ),
                      Text(
                        'Deadline: ${TimeUtils.formatDateTime(_deadline)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || !_isFormValid)
              ? null
              : () => _saveProject(
                  _startDate,
                  _deadline,
                  0,
                  int.tryParse(_currentController.text)!,
                  int.tryParse(_endGoalController.text)!,
                  _unitController.text,
                  widget.projectData == null
                      ? widget.categoryId
                      : widget.projectData!.category,
                ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String? _validateProjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Task name cannot be empty';
    }

    return null;
  }

  void _updateButtonState() {
    setState(() {});
  }

  Future<void> _chooseNewProjectColor(
    BuildContext context,
    WidgetRef ref,
    ProjectData project,
  ) async {
    Color selectedColor = project.color != null
        ? Color(project.color!)
        : Colors.blue;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("cancel"),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(projectsNotifierProvider.notifier)
                    .updateProject(
                      project.id,
                      ProjectCompanion(color: Value(selectedColor.toARGB32())),
                    );
                ref.invalidate(projectProvider(project.id));
                ref.invalidate(projectIntervalsNotifierProvider);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProject(
    DateTime startDate,
    DateTime deadline,
    int initial,
    int current,
    int goal,
    String unit,
    int? category,
  ) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projectName = _projectNameController.text.trim();

      if (widget.projectData == null) {
        await ref
            .read(projectsNotifierProvider.notifier)
            .addProject(
              name: projectName,
              startDate: startDate,
              deadline: deadline,
              startPoint: initial,
              current: current,
              goal: goal,
              unit: unit,
              category: category,
            );
      } else {
        await ref
            .read(projectsNotifierProvider.notifier)
            .updateProject(
              widget.projectData!.id,
              ProjectCompanion(
                name: Value(projectName),
                startDate: Value(startDate),
                deadline: Value(deadline),
                startPoint: Value(initial),
                current: Value(current),
                goal: Value(goal),
                unit: Value(unit),
                category: Value(category),
              ),
            );
        ref.invalidate(projectStatsNotifier(widget.projectData!.id));
        ref.invalidate(projectProvider(widget.projectData!.id));
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save task: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime today,
    bool isDeadline,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: today.subtract(Duration(days: 1827)),
      currentDate: today,
      lastDate: today.add(Duration(days: 1827)),
    );

    if (picked != null) {
      setState(() {
        _startDate = isDeadline ? _startDate : picked;
        _deadline = isDeadline ? picked : _deadline;
      });
    }
  }
}

Future<void> showAddProjectDialog({
  required BuildContext context,
  int? categoryId,
  ProjectData? projectData,
}) async {
  await showDialog(
    context: context,
    builder: (context) =>
        AddProjectDialog(categoryId: categoryId, projectData: projectData),
  );
}
