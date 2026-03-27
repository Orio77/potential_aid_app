import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/breakdown/constants/task_breakdown_constants.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/breakdown/managers/subtask_state_manager.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/timeline/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/breakdown/widgets/arrow_painter.dart';
import 'package:potential_aid_app/breakdown/widgets/subtask_card.dart';
import 'package:potential_aid_app/breakdown/widgets/subtask_buttons.dart';

class TaskBreakdownScreen extends ConsumerStatefulWidget {
  final TaskData task;

  const TaskBreakdownScreen({super.key, required this.task});

  @override
  ConsumerState<TaskBreakdownScreen> createState() =>
      _TaskBreakdownScreenState();
}

class _TaskBreakdownScreenState extends ConsumerState<TaskBreakdownScreen> {
  late final SubtaskStateManager _stateManager;
  late bool showCompleted;
  final GlobalKey mainTaskKey = GlobalKey();
  bool isLoading = true;
  double _dynamicTotalWidth =
      TaskBreakdownConstants.mainTaskWidth +
      TaskBreakdownConstants.subtasksWidth +
      TaskBreakdownConstants.spacing +
      TaskBreakdownConstants.padding;
  double _dynamicSubtasksWidth = TaskBreakdownConstants.subtasksWidth;

  @override
  void initState() {
    super.initState();
    showCompleted = false;
    _stateManager = SubtaskStateManager();
    _initializeSubtasks();
  }

  @override
  void dispose() {
    _stateManager.dispose();
    super.dispose();
  }

  // Initialization and data loading

  void _initializeSubtasks() async {
    final notCompletedFilter = <Expression<bool> Function($TaskTable)>[
      (table) => table.isCompleted.equals(false),
    ];
    final subtasksData = await ref
        .read(projectTasksNotifier(widget.task.projectId).notifier)
        .getSubtasks(widget.task.id, showCompleted ? [] : notCompletedFilter);

    if (subtasksData.isEmpty) {
      _stateManager.initializeEmpty();
    } else {
      final subtasksWithCounts = <({TaskData taskData, int subtaskCount})>[];

      for (final subtask in subtasksData) {
        final subtasksOfSubtaskData = await ref
            .read(projectTasksNotifier(subtask.projectId).notifier)
            .getSubtasks(subtask.id, showCompleted ? [] : notCompletedFilter);
        subtasksWithCounts.add((
          taskData: subtask,
          subtaskCount: subtasksOfSubtaskData.length,
        ));
      }

      _stateManager.initializeFromData(subtasksWithCounts);
    }

    setState(() {
      _dynamicTotalWidth = _stateManager.calculateDynamicWidth(
        widget.task.name,
      );
      _dynamicSubtasksWidth = _stateManager.calculateDynamicSubtasksWidth();
      isLoading = false;
    });
  }

  // User actions

  void _addSubtask() {
    final newSubtask = _stateManager.addSubtask();
    setState(() {
      _dynamicTotalWidth = _stateManager.calculateDynamicWidth(
        widget.task.name,
      );
      _dynamicSubtasksWidth = _stateManager.calculateDynamicSubtasksWidth();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      newSubtask.focusNode.requestFocus();
    });
  }

  void _toggleSearchMode(int index) {
    final subtask = _stateManager.getSubtask(index);
    if (subtask == null) return;

    final updatedSubtask = subtask.copyWith(
      isSearchMode: !subtask.isSearchMode,
    );

    setState(() {
      _stateManager.updateSubtask(index, updatedSubtask);
      if (updatedSubtask.isSearchMode) {
        updatedSubtask.searchController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          updatedSubtask.searchFocusNode.requestFocus();
        });
      } else {
        updatedSubtask.searchController.clear();
      }
    });
  }

  void _selectExistingTask(int index, TaskData selectedTask) {
    final subtask = _stateManager.getSubtask(index);
    if (subtask == null) return;

    setState(() {
      subtask.controller.text = selectedTask.name;

      final updatedSubtask = subtask.copyWith(
        isExisting: true,
        savedId: selectedTask.id,
        isSearchMode: false,
      );

      _stateManager.updateSubtask(index, updatedSubtask);
      updatedSubtask.searchController.clear();

      _updateSubtaskCount(index, selectedTask.id);
      _dynamicTotalWidth = _stateManager.calculateDynamicWidth(
        widget.task.name,
      );
      _dynamicSubtasksWidth = _stateManager.calculateDynamicSubtasksWidth();
    });
  }

  void _removeSubtask(int index) async {
    final subtask = _stateManager.getSubtask(index);
    if (subtask != null && subtask.isExisting) {
      await _deleteParentTaskFromSubtasks(index);
    }
    _stateManager.removeSubtask(index);
    setState(() {
      _dynamicTotalWidth = _stateManager.calculateDynamicWidth(
        widget.task.name,
      );
      _dynamicSubtasksWidth = _stateManager.calculateDynamicSubtasksWidth();
    });
  }

  Future<void> _saveSubtasks() async {
    var notifier = ref.read(
      projectTasksNotifier(widget.task.projectId).notifier,
    );
    final date = ref.read(dateNotifierProvider).toDateTimeUnspecified();

    final subtasks = _stateManager.subtasks;
    for (int i = 0; i < subtasks.length; i++) {
      final subtask = subtasks[i];
      final taskDepth = widget.task.depth + 1;

      if (subtask.isNew && subtask.hasValidContent) {
        final taskId = await notifier.addTask(
          subtask.controller.text.trim(),
          widget.task.projectId,
          date,
          parentTaskId: widget.task.id,
          depth: taskDepth,
          orderIndex: i,
        );

        final updatedSubtask = subtask.copyWith(
          savedId: taskId,
          isExisting: true,
        );
        _stateManager.updateSubtask(i, updatedSubtask);
      } else if (subtask.isExisting) {
        await notifier.updateTask(
          subtask.savedId,
          TaskCompanion(
            parentTaskId: Value(widget.task.id),
            orderIndex: Value(i),
          ),
        );
      }

      ref.invalidate(taskCardsNotifierProvider(taskDepth));
    }
  }

  Future<void> _updateSubtaskCount(int index, int taskId) async {
    final subtasksOfTask = await ref
        .read(projectTasksNotifier(widget.task.projectId).notifier)
        .getSubtasks(taskId);

    final subtask = _stateManager.getSubtask(index);
    if (subtask != null) {
      final updatedSubtask = subtask.copyWith(
        subtaskCount: subtasksOfTask.length,
      );
      setState(() {
        _stateManager.updateSubtask(index, updatedSubtask);
      });
    }
  }

  Future<void> _deleteParentTaskFromSubtasks(int index) async {
    final subtask = _stateManager.getSubtask(index);
    if (subtask != null && subtask.savedId != -1) {
      await ref
          .read(projectTasksNotifier(widget.task.projectId).notifier)
          .updateTask(
            subtask.savedId,
            TaskCompanion(parentTaskId: Value(null)),
          );
    }
  }

  void _handleTaskCompletion() {
    setState(() {
      isLoading = true;
    });
    _initializeSubtasks();
  }

  void _handleTextChanged(String value) {
    setState(() {
      _dynamicTotalWidth = _stateManager.calculateDynamicWidth(
        widget.task.name,
      );
      _dynamicSubtasksWidth = _stateManager.calculateDynamicSubtasksWidth();
    });
  }

  // Build methods

  Widget _buildArrows() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: ArrowPainter(
            mainTaskKey: mainTaskKey,
            subtaskKeys: _stateManager.subtasks.map((s) => s.key).toList(),
            stackContext: context,
          ),
          size: Size(_dynamicTotalWidth, double.infinity),
        );
      },
    );
  }

  Widget _buildTaskBreakdownScreen(TaskData task) {
    return SizedBox(
      width: _dynamicTotalWidth,
      child: Padding(
        padding: EdgeInsets.all(TaskBreakdownConstants.padding / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMainTaskCard(task),
            SizedBox(width: TaskBreakdownConstants.spacing),
            _buildSubtasksList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTaskCard(TaskData task) {
    return SizedBox(
      width: TaskBreakdownConstants.mainTaskWidth,
      child: Center(
        child: Card(
          key: mainTaskKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: TaskBreakdownConstants.maxTaskHeight,
                minHeight: TaskBreakdownConstants.minTaskHeight,
              ),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.task.parentTaskId != null)
                      GoToParentTaskButton(task: widget.task),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          task.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtasksList() {
    return SizedBox(
      width: _dynamicSubtasksWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: _stateManager.subtasks.length,
              itemBuilder: (context, index) {
                final subtask = _stateManager.getSubtask(index);
                if (subtask == null) {
                  return SizedBox.shrink(key: ValueKey('empty_$index'));
                }
                return SubtaskCard(
                  key: Key(subtask.id),
                  subtask: subtask,
                  index: index,
                  parentTask: widget.task,
                  onToggleSearch: _toggleSearchMode,
                  onSelectExistingTask: _selectExistingTask,
                  onRemove: _removeSubtask,
                  onSaveNeeded: _saveSubtasks,
                  onComplete: _handleTaskCompletion,
                  onTextChanged: _handleTextChanged,
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  _stateManager.reorderSubtasks(oldIndex, newIndex);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowCompletedSwitch() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.circle_outlined),
        Switch(
          value: showCompleted,
          onChanged: (value) {
            setState(() {
              showCompleted = !showCompleted;
              isLoading = true;
            });
            _initializeSubtasks();
          },
        ),
        const Icon(Icons.task_alt_rounded),
      ],
    );
  }

  Widget _buildFloatingActionButtons() {
    if (isLoading) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "add_subtask",
          onPressed: _addSubtask,
          child: const Icon(Icons.add),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: "save_subtasks",
          onPressed: () async {
            await _saveSubtasks();
            setState(() {});
          },
          child: const Icon(Icons.save),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Depth: ${widget.task.depth}'),
        centerTitle: true,
        actions: [_buildShowCompletedSwitch()],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _dynamicTotalWidth,
                child: Stack(
                  children: [
                    _buildTaskBreakdownScreen(widget.task),
                    if (!isLoading) IgnorePointer(child: _buildArrows()),
                  ],
                ),
              ),
            ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }
}
