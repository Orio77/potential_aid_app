import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/constants/task_breakdown_constants.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/managers/subtask_state_manager.dart';
import 'package:potential_aid_app/models/subtask_item.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/widgets/projects/complete_task_dialog.dart';
import 'package:potential_aid_app/widgets/util/arrow_painter.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

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
      // Prepare data with subtask counts
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

  void _addSubtask() {
    final newSubtask = _stateManager.addSubtask();
    setState(() {
      _dynamicTotalWidth = _stateManager.calculateDynamicWidth(
        widget.task.name,
      );
      _dynamicSubtasksWidth = _stateManager.calculateDynamicSubtasksWidth();
    });

    // Focus on the newly added subtask after the widget is built
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

  void _correctIndexes(int index) {
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

        // Update the subtask with the new saved ID
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

  Widget _buildBreakdownSubtaskButton(int index) {
    final navigator = Navigator.of(context);
    final subtask = _stateManager.getSubtask(index);

    return IconButton(
      onPressed: () async {
        if (subtask == null) return;

        if (subtask.savedId != TaskBreakdownConstants.newSubtaskId) {
          final task = await ref
              .read(projectTasksNotifier(widget.task.projectId).notifier)
              .getTask(subtask.savedId);
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => TaskBreakdownScreen(task: task),
            ),
          );
        } else {
          await _saveSubtasks();
          final updatedSubtask = _stateManager.getSubtask(index);
          if (updatedSubtask != null &&
              updatedSubtask.savedId != TaskBreakdownConstants.newSubtaskId) {
            final task = await ref
                .read(projectTasksNotifier(widget.task.projectId).notifier)
                .getTask(updatedSubtask.savedId);
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => TaskBreakdownScreen(task: task),
              ),
            );
          }
        }
      },
      icon: Icon(Icons.account_tree_rounded),
    );
  }

  Widget _buildGoToParentTaskButton() {
    final navigator = Navigator.of(context);

    return IconButton(
      onPressed: () async {
        final parentTask = await ref
            .read(projectTasksNotifier(widget.task.projectId).notifier)
            .getTask(widget.task.parentTaskId!);
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => TaskBreakdownScreen(task: parentTask),
          ),
        );
      },
      icon: Icon(Icons.arrow_circle_left_outlined),
    );
  }

  Widget _buildRemoveSubtaskButton(int index) {
    return IconButton(
      onPressed: () async {
        final subtask = _stateManager.getSubtask(index);
        if (subtask != null && subtask.isExisting) {
          await _deleteParentTaskFromSubtasks(index);
        }
        _correctIndexes(index);
      },
      icon: Icon(Icons.delete),
    );
  }

  Widget _buildSubtaskCountInfo(int index) {
    final subtask = _stateManager.getSubtask(index);
    final count = subtask?.subtaskCount ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(3, 0, 0, 0),
      child: Container(
        width: TaskBreakdownConstants.subtaskCountCircleSize,
        height: TaskBreakdownConstants.subtaskCountCircleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: TaskBreakdownConstants.subtaskCountFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(int index) {
    final subtask = _stateManager.getSubtask(index);
    if (subtask == null) return SizedBox.shrink();

    return SearchTextField<TaskData, TaskSearchNotifier>(
      controller: subtask.searchController,
      focusNode: subtask.searchFocusNode,
      labelText: 'Search existing tasks',
      searchProvider: taskSearchProvider,
      getDisplayText: (task) => task.name,
      onItemSelected: (task) => _selectExistingTask(index, task),
      leadingIcon: (task) =>
          const Icon(Icons.task_alt, size: 16, color: Colors.blue),
      trailingIcon: const Icon(
        Icons.arrow_forward_ios,
        size: 12,
        color: Colors.grey,
      ),
      predicates: [
        (task) => task.projectId == widget.task.projectId, // Same project
        (task) => !task.isCompleted, // Not completed
        (task) => task.id != widget.task.id, // Not the current task
        (task) => !_stateManager.subtasks.any(
          (s) => s.savedId == task.id,
        ), // Not already added
      ],
      maxResults: TaskBreakdownConstants.maxSearchResults,
    );
  }

  Widget _buildSubtaskCard(SubtaskItem? subtask, int index) {
    if (subtask == null) {
      return SizedBox.shrink(key: ValueKey('empty_${subtask!.id}'));
    }

    final isSubtaskCompleted =
        subtask.taskData != null && subtask.taskData!.isCompleted;

    return Card(
      key: Key(subtask.id),
      color: isSubtaskCompleted ? Colors.greenAccent[100] : null,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: subtask.isSearchMode
                  ? _buildSearchField(index)
                  : TextField(
                      controller: subtask.controller,
                      focusNode: subtask.focusNode,
                      readOnly: subtask.isExisting,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Subtask ${index + 1}',
                        fillColor: subtask.isExisting
                            ? (isSubtaskCompleted
                                  ? Colors.green[300]
                                  : Colors.grey[400])
                            : null,
                        filled: subtask.isExisting,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _dynamicTotalWidth = _stateManager
                              .calculateDynamicWidth(widget.task.name);
                          _dynamicSubtasksWidth = _stateManager
                              .calculateDynamicSubtasksWidth();
                        });
                      },
                    ),
            ),

            _buildSubtaskCountInfo(index),
            _buildCompleteTaskButton(subtask),
            _buildChangeDeadlineForTomorrowButton(subtask),
            _buildToggleSearchButton(index, subtask),
            _buildBreakdownSubtaskButton(index),
            _buildRemoveSubtaskButton(index),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSearchButton(int index, SubtaskItem subtask) {
    return subtask.isExisting
        ? SizedBox.shrink()
        : IconButton(
            onPressed: () => _toggleSearchMode(index),
            icon: Icon(Icons.search),
          );
  }

  Widget _buildChangeDeadlineForTomorrowButton(SubtaskItem subtask) {
    return !subtask.isExisting
        ? SizedBox.shrink()
        : IconButton(
            onPressed: () async {
              final notCompletedFilter =
                  <Expression<bool> Function($TaskTable)>[
                    (table) => table.isCompleted.equals(false),
                  ];
              final today = ref
                  .read(dateNotifierProvider.notifier)
                  .getTodaysDate();
              var tomorrow = today.addDays(1).toDateTimeUnspecified();
              await ref
                  .read(projectTasksNotifier(widget.task.projectId).notifier)
                  .updateTask(
                    subtask.savedId,
                    TaskCompanion(deadline: Value(tomorrow)),
                  );
              _updateAllNestedSubtasksDeadline(
                subtask.savedId,
                tomorrow,
                notCompletedFilter,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Center(
                    child: Text(
                      "Moved subtask to: ${tomorrow.day}-${tomorrow.month}-${tomorrow.year}",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(milliseconds: 1000), // 0.5 seconds
                ),
              );
            },
            icon: Icon(Icons.edit_calendar_rounded),
          );
  }

  Future<void> _updateAllNestedSubtasksDeadline(
    int parentTaskId,
    DateTime deadline,
    List<Expression<bool> Function($TaskTable)> filters,
  ) async {
    final notifier = ref.read(
      projectTasksNotifier(widget.task.projectId).notifier,
    );

    final subtasks = await notifier.getSubtasks(parentTaskId, filters);

    for (final subtask in subtasks) {
      await notifier.updateTask(
        subtask.id,
        TaskCompanion(deadline: Value(deadline)),
      );

      await _updateAllNestedSubtasksDeadline(subtask.id, deadline, filters);
    }
  }

  Widget _buildCompleteTaskButton(SubtaskItem subtask) {
    return (!subtask.isExisting ||
            subtask.taskData == null ||
            subtask.taskData!.isCompleted)
        ? SizedBox.shrink()
        : IconButton(
            onPressed: () async {
              final task = await ref
                  .read(projectTasksNotifier(widget.task.projectId).notifier)
                  .getTask(subtask.savedId);
              await showCompleteTaskDialog(context, task);
              setState(() {
                isLoading = true;
              });
              _initializeSubtasks();
            },
            icon: Icon(Icons.task_alt_sharp),
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
            SizedBox(
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
                              _buildGoToParentTaskButton(),
                            Flexible(
                              child: SingleChildScrollView(
                                child: Text(
                                  task.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
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
            ),
            SizedBox(width: TaskBreakdownConstants.spacing),
            SizedBox(
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
                        return _buildSubtaskCard(subtask, index);
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
            ),
          ],
        ),
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
      floatingActionButton: isLoading
          ? null
          : Row(
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
                    setState(() {}); // update state
                  },
                  child: const Icon(Icons.save),
                ),
              ],
            ),
    );
  }
}
