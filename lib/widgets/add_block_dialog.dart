import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_search_notifier.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/providers/settings_notifier.dart';
import 'package:potential_aid_app/utils/time_utils.dart';
import 'package:potential_aid_app/widgets/add_task_dialog.dart';
import 'package:potential_aid_app/widgets/duration_picker_dialog.dart';
import 'package:potential_aid_app/widgets/schedule/block_add_task_list.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

class AddBlockDialog extends ConsumerStatefulWidget {
  const AddBlockDialog({super.key});

  @override
  ConsumerState<AddBlockDialog> createState() => _AddBlockDialogState();
}

class _AddBlockDialogState extends ConsumerState<AddBlockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _focusNode = FocusNode();
  late TimeOfDay _startTime;
  int _durationMinutes = 60;
  String? _errorMessage;
  ProjectData? _selectedProject;
  List<TaskData> _selectedTasks = [];

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingsNotifierProvider);
    _projectNameController.addListener(() {
      setState(() {
        if (_projectNameController.text.isEmpty) {
          _selectedProject = null;
        }
      });
    });

    final defaultStartTime = settings.defaultStartTime;
    _durationMinutes = settings.defaultTaskLength;
    _startTime = TimeOfDay(
      hour: defaultStartTime ~/ 60,
      minute: defaultStartTime % 60,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _initializeStartTime();
    });
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  Future<void> _initializeStartTime() async {
    final calculatedTime = await _calculateNextAvailableTime();
    if (mounted) {
      setState(() {
        _startTime = calculatedTime;
      });
    }
  }

  Future<TimeOfDay> _calculateNextAvailableTime() async {
    final settings = ref.read(settingsNotifierProvider);
    final schedule = ref.read(scheduleNotifierProvider);

    if (schedule.isEmpty) {
      final defaultMinutes = settings.defaultStartTime;
      return TimeOfDay(hour: defaultMinutes ~/ 60, minute: defaultMinutes % 60);
    }

    final lastBlockId = schedule.last;
    final lastBlock = await ref
        .read(scheduleNotifierProvider.notifier)
        .getBlockById(lastBlockId);
    final lastEndMinutes =
        lastBlock!.startMinuteOfDay + lastBlock.lengthMinutes;
    final nextStartMinutes = lastEndMinutes + settings.defaultBreakTime;

    return TimeOfDay(
      hour: nextStartMinutes ~/ 60,
      minute: nextStartMinutes % 60,
    );
  }

  String? _validateProjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project name cannot be empty';
    }

    return null;
  }

  void _onTasksChanged(List<TaskData> tasks) {
    setState(() {
      _selectedTasks = tasks;
    });
  }

  Future<void> _saveBlock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProject == null && _projectNameController.text.isNotEmpty) {
      final now = ref.read(dateNotifierProvider).toDateTimeUnspecified();
      final newProjectId = await ref
          .read(projectsNotifierProvider.notifier)
          .addProject(
            name: _projectNameController.text.trim(),
            startDate: now,
            deadline: now.add(Duration(days: 7)),
            startPoint: 0,
            current: 0,
            goal: 1,
            unit: "completed",
          );

      // Get the newly created project
      final projects = ref.read(projectsNotifierProvider);
      _selectedProject = projects.firstWhere((p) => p.id == newProjectId);
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final blockId = await ref
          .read(scheduleNotifierProvider.notifier)
          .addBlock(
            TimeUtils.datetimeToMinutes(_startTime),
            _durationMinutes,
            _selectedProject!.id,
          );
      if (_selectedTasks.isNotEmpty) {
        await _saveBlockTasks(blockId, _selectedTasks);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save block $e';
        });
      }
    }
  }

  Future<void> _saveBlockTasks(int blockId, List<TaskData> tasks) async {
    await ref
        .read(scheduleNotifierProvider.notifier)
        .assignTasksToBlock(blockId, tasks.map((t) => t.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('Add New Block')),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchTextField<ProjectData, ProjectSearchNotifier>(
                controller: _projectNameController,
                focusNode: _focusNode,
                labelText: 'Project name',
                validator: _validateProjectName,
                searchProvider: projectSearchProvider,
                getDisplayText: (block) => block.name,
                onItemSelected: (projectData) {
                  setState(() {
                    _selectedProject = projectData;
                  });
                },
                leadingIcon: (project) =>
                    const Icon(Icons.task_alt, size: 16, color: Colors.blue),
                trailingIcon: const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 8),

              if (_selectedProject != null) ...[
                ElevatedButton(
                  onPressed: () =>
                      showAddTaskDialog(context, _selectedProject!.id),
                  child: Icon(Icons.add_task),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: BlockAddTaskList(
                    project: _selectedProject,
                    onTasksChanged: _onTasksChanged,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Start Time'),
                subtitle: Text(_startTime.format(context)),
                onTap: _pickStartTime,
              ),

              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Duration'),
                subtitle: Text('$_durationMinutes minutes'),
                onTap: _pickDuration,
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
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_projectNameController.text.isEmpty)
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  await _saveBlock();
                  if (mounted && _errorMessage == null) {
                    navigator.pop();
                  }
                },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickDuration() async {
    final int? picked = await showDialog(
      context: context,
      builder: (context) =>
          DurationPickerDialog(initialDuration: _durationMinutes),
    );

    if (picked != null) {
      setState(() {
        _durationMinutes = picked;
      });
    }
  }
}

Future<void> showAddBlockDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => const AddBlockDialog(),
  );
}
