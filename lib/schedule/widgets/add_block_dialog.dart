import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_search_notifier.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/schedule/providers/schedule_notifier.dart';
import 'package:potential_aid_app/providers/settings_notifier.dart';
import 'package:potential_aid_app/schedule/services/add_block_service.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';
import 'package:potential_aid_app/utils/time_utils.dart';
import 'package:potential_aid_app/schedule/widgets/block_add_task_list.dart';
import 'package:potential_aid_app/schedule/widgets/tasks_for_deadline_dialog.dart';
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
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  bool _hasRequestedInitialFocus = false;
  bool _hasInitializedStartTime = false;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  int _defaultDurationMinutes = 60;
  String? _errorMessage;
  ProjectData? _selectedProject;
  List<TaskData> _selectedTasks = [];
  final Map<int, List<TaskData>> _cachedProjectTasks = {};

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingsNotifierProvider);
    _projectNameController.addListener(() {
      setState(() {
        if (_projectNameController.text.isEmpty) {
          if (_selectedProject != null) {
            _cachedProjectTasks[_selectedProject!.id] = List.from(
              _selectedTasks,
            );
          }
          _selectedProject = null;
          _selectedTasks.clear();
        }
      });
    });

    final defaultStartTime = settings.defaultStartTime;
    _defaultDurationMinutes = settings.defaultTaskLength;
    _startTime = TimeOfDay(
      hour: defaultStartTime ~/ 60,
      minute: defaultStartTime % 60,
    );
    _endTime = _addMinutes(_startTime, _defaultDurationMinutes);
    _startTimeController.text = _formatTime(_startTime);
    _endTimeController.text = _formatTime(_endTime);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRequestedInitialFocus) {
        _focusNode.requestFocus();
        _hasRequestedInitialFocus = true;
      }
      if (!_hasInitializedStartTime) {
        _hasInitializedStartTime = true;
        _initializeStartTime();
      }
    });
  }

  Future<void> _initializeStartTime() async {
    final calculatedTime = await AddBlockService.calculateNextAvailableTime(
      ref,
    );
    if (mounted) {
      setState(() {
        _startTime = calculatedTime;
        _endTime = _addMinutes(_startTime, _defaultDurationMinutes);
        _startTimeController.text = _formatTime(_startTime);
        _endTimeController.text = _formatTime(_endTime);
      });
    }
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _focusNode.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();

    super.dispose();
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? _parseTime(String text) {
    final match = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*$').firstMatch(text);
    if (match == null) return null;
    final h = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  static TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
    final total = (t.hour * 60 + t.minute + minutes) % (24 * 60);
    final wrapped = total < 0 ? total + 24 * 60 : total;
    return TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
  }

  int get _durationMinutes {
    final start = TimeUtils.datetimeToMinutes(_startTime);
    final end = TimeUtils.datetimeToMinutes(_endTime);
    return end - start;
  }

  void _onTasksChanged(List<TaskData> tasks) {
    setState(() {
      _selectedTasks = tasks;
    });
  }

  Future<void> saveBlock() async {
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
      final duration = _durationMinutes;
      final blockId = await ref
          .read(scheduleNotifierProvider.notifier)
          .addBlock(
            TimeUtils.datetimeToMinutes(_startTime),
            duration,
            _selectedProject!.id,
          );
      if (_selectedTasks.isNotEmpty) {
        await saveBlockTasks(blockId, _selectedTasks);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save block $e';
        });
      }
    }
  }

  Future<void> saveBlockTasks(int blockId, List<TaskData> tasks) async {
    await ref
        .read(scheduleNotifierProvider.notifier)
        .assignTasksToBlock(blockId, tasks.map((t) => t.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final deadlineDate = ref.watch(dateNotifierProvider);

    return AlertDialog(
      title: const Center(child: Text('Add New Block')),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SearchTextField<ProjectData, ProjectSearchNotifier>(
                      controller: _projectNameController,
                      focusNode: _focusNode,
                      labelText: 'Project name',
                      validator: AddBlockService.validateProjectName,
                      searchProvider: projectSearchProvider,
                      getDisplayText: (block) => block.name,
                      onItemSelected: (projectData) {
                        setState(() {
                          if (_selectedProject != null) {
                            _cachedProjectTasks[_selectedProject!.id] =
                                List.from(_selectedTasks);
                          }

                          _selectedProject = projectData;

                          if (_cachedProjectTasks.containsKey(projectData.id)) {
                            _selectedTasks = List.from(
                              _cachedProjectTasks[projectData.id]!,
                            );
                          } else {
                            _selectedTasks.clear();
                          }
                        });
                      },
                      leadingIcon: (project) => const Icon(
                        Icons.task_alt,
                        size: 16,
                        color: Colors.blue,
                      ),
                      trailingIcon: const Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  if (_selectedProject != null) ...[
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProjectScreen(data: _selectedProject!),
                            ),
                          );
                        },
                        icon: Icon(Icons.arrow_right_alt_rounded),
                      ),
                    ),
                  ],
                ],
              ),

              if (_selectedProject != null) ...[
                const SizedBox(height: 8),

                SizedBox(
                  height: 240,
                  child: BlockAddTaskList(
                    project: _selectedProject,
                    initialTasks: _selectedTasks,
                    onTasksChanged: _onTasksChanged,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Start',
                      controller: _startTimeController,
                      onParsed: _onStartParsed,
                      onPickClock: pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'End',
                      controller: _endTimeController,
                      onParsed: _onEndParsed,
                      onPickClock: pickEndTime,
                      validator: (_) => _durationMinutes <= 0
                          ? 'End must be after start'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Duration: ${_durationMinutes <= 0 ? '--' : _durationMinutes} minutes',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final List<TaskData>? selectedTasks =
                await showTasksForDeadlineDialog(context, deadlineDate);

            if (selectedTasks != null && selectedTasks.isNotEmpty) {
              final projectId = selectedTasks.first.projectId;
              final projectData = await ref
                  .read(projectsNotifierProvider.notifier)
                  .getProjectById(projectId);
              _projectNameController.text = projectData!.name;
              setState(() {
                _selectedTasks = selectedTasks;
                _selectedProject = projectData;
              });
            }
          },
          child: Icon(Icons.list),
        ),
        ElevatedButton(
          onPressed: (_projectNameController.text.isEmpty)
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  await saveBlock();
                  if (mounted && _errorMessage == null) {
                    navigator.pop();
                  }
                },
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _onStartParsed(TimeOfDay t) {
    setState(() {
      final previousDuration = _durationMinutes;
      _startTime = t;
      if (previousDuration <= 0) {
        _endTime = _addMinutes(_startTime, _defaultDurationMinutes);
        _endTimeController.text = _formatTime(_endTime);
      } else if (TimeUtils.datetimeToMinutes(_endTime) <=
          TimeUtils.datetimeToMinutes(_startTime)) {
        _endTime = _addMinutes(_startTime, previousDuration);
        _endTimeController.text = _formatTime(_endTime);
      }
    });
  }

  void _onEndParsed(TimeOfDay t) {
    setState(() {
      _endTime = t;
    });
  }

  Future<void> pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
        _startTimeController.text = _formatTime(picked);
        if (TimeUtils.datetimeToMinutes(_endTime) <=
            TimeUtils.datetimeToMinutes(_startTime)) {
          _endTime = _addMinutes(_startTime, _defaultDurationMinutes);
          _endTimeController.text = _formatTime(_endTime);
        }
      });
    }
  }

  Future<void> pickEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
        _endTimeController.text = _formatTime(picked);
      });
    }
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final void Function(TimeOfDay) onParsed;
  final VoidCallback onPickClock;
  final String? Function(String?)? validator;

  const _TimeField({
    required this.label,
    required this.controller,
    required this.onParsed,
    required this.onPickClock,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
        LengthLimitingTextInputFormatter(5),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintText: 'HH:MM',
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          tooltip: 'Pick with clock',
          onPressed: onPickClock,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        if (_AddBlockDialogState._parseTime(value) == null) {
          return 'Invalid time';
        }
        if (validator != null) return validator!(value);
        return null;
      },
      onChanged: (value) {
        final parsed = _AddBlockDialogState._parseTime(value);
        if (parsed != null) onParsed(parsed);
      },
    );
  }
}

Future<void> showAddBlockDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) => const AddBlockDialog(),
  );
}
