import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/providers/block_with_tasks_notifier.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_search_notifier.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/schedule/services/add_block_service.dart';
import 'package:potential_aid_app/schedule/services/edit_block_service.dart';
import 'package:potential_aid_app/schedule/widgets/block_add_task_list.dart';
import 'package:potential_aid_app/schedule/widgets/tasks_for_deadline_dialog.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';
import 'package:potential_aid_app/widgets/common/duration_picker_dialog.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';
import 'package:time_machine/time_machine.dart';

class EditBlockDialog extends ConsumerStatefulWidget {
  final int blockId;

  const EditBlockDialog({super.key, required this.blockId});

  @override
  ConsumerState<EditBlockDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends ConsumerState<EditBlockDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _projectNameController;
  bool _isLoading = false;
  String? _errorMessage;

  ProjectData? _selectedProject;
  TimeOfDay? _startTime;
  int? _duration;
  bool _isInitialized = false;
  late List<TaskData> _selectedTasks;

  @override
  void initState() {
    super.initState();
    _selectedTasks = [];
    _projectNameController = TextEditingController();
    _projectNameController.addListener(() {
      if (_projectNameController.text.isEmpty) {
        setState(() {
          _selectedProject = null;
          _selectedTasks = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  void _initializeFromBlock(
    BlockWithTasks blockWithTasks,
    ProjectData project,
  ) {
    if (!_isInitialized) {
      _startTime = EditBlockService.minutesToTimeOfDay(
        blockWithTasks.block.startMinuteOfDay,
      );
      _duration = blockWithTasks.block.lengthMinutes;

      _selectedProject = project;
      _projectNameController.text = project.name;
      _selectedTasks = List.from(blockWithTasks.tasks ?? []);

      _isInitialized = true;
    }
  }

  Future<void> _saveEditBlock(int blockId) async {
    if (!_formKey.currentState!.validate() ||
        _startTime == null ||
        _duration == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(scheduleNotifierProvider.notifier)
          .editBlock(
            blockId,
            EditBlockService.timeOfDayToMinutes(_startTime!),
            _duration,
            _selectedProject?.id,
            _selectedTasks.map((t) => t.id).toList(),
          );
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

  @override
  Widget build(BuildContext context) {
    final deadlineDate = ref.watch(dateNotifierProvider);
    final blockAsync = ref.watch(blockTasksNotifier(widget.blockId));

    return blockAsync.when(
      data: (data) {
        final projectAsync = ref.watch(projectProvider(data.block.projectId));
        return projectAsync.when(
          data: (project) {
            _initializeFromBlock(data, project!);
            return _buildEditBlockDialog(data, project, deadlineDate);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: (Text("Error: $error"))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(child: (Text("Error: $error"))),
    );
  }

  Widget _buildEditBlockDialog(
    BlockWithTasks block,
    ProjectData project,
    LocalDate deadlineDate,
  ) {
    if (_startTime == null || _duration == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AlertDialog(
      title: const Center(child: Text('Edit Block')),
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
                      labelText: 'Project name',
                      validator: AddBlockService.validateProjectName,
                      searchProvider: projectSearchProvider,
                      getDisplayText: (block) => block.name,
                      onItemSelected: (projectData) {
                        setState(() {
                          _selectedProject = projectData;
                          _selectedTasks = [];
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
                  height: 190,
                  child: BlockAddTaskList(
                    project: _selectedProject,
                    initialTasks: _selectedTasks,
                    onTasksChanged: (tasks) {
                      setState(() {
                        _selectedTasks = tasks;
                      });
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Start Time'),
                subtitle: Text(_startTime!.format(context)),
                onTap: _isLoading ? null : _pickStartTime,
              ),

              ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Duration'),
                subtitle: Text('$_duration minutes'),
                onTap: _isLoading ? null : _pickDuration,
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
          onPressed: _isLoading ? null : (() => _saveEditBlock(widget.blockId)),
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

  Future<void> _pickStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime!,
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
      builder: (context) => DurationPickerDialog(initialDuration: _duration!),
    );

    if (picked != null) {
      setState(() {
        _duration = picked;
      });
    }
  }
}

Future<void> showEditBlockDialog(
  BuildContext context, {
  required int blockId,
}) async {
  await showDialog(
    context: context,
    builder: (context) => EditBlockDialog(blockId: blockId),
  );
}
