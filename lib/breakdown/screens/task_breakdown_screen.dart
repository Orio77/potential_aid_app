import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/breakdown/constants/task_breakdown_constants.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/breakdown/managers/subtask_state_manager.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/projects/screens/project_screen.dart';
import 'package:potential_aid_app/projects/widgets/add_task_dialog.dart';
import 'package:potential_aid_app/timeline/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/breakdown/widgets/arrow_painter.dart';
import 'package:potential_aid_app/breakdown/widgets/main_task_card.dart';
import 'package:potential_aid_app/breakdown/widgets/reorder_subtask_list.dart';
import 'package:potential_aid_app/breakdown/widgets/reparent_subtask_list.dart';

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
  bool _reparentMode = false;
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
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _stateManager.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    if (event is! KeyDownEvent) return false;
    if (!HardwareKeyboard.instance.isControlPressed) return false;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _addSubtask();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyS) {
      if (!isLoading) {
        _saveSubtasks().then((_) {
          if (mounted) setState(() {});
        });
      }
      return true;
    }
    return false;
  }

  // ── Initialization ──────────────────────────────────────────────────────────

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

  // ── User actions ────────────────────────────────────────────────────────────

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
      await ref
          .read(projectTasksNotifier(widget.task.projectId).notifier)
          .deleteTask(subtask.savedId);
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
          name: subtask.controller.text.trim(),
          projectId: widget.task.projectId,
          deadline: date,
          startPoint: 0,
          current: 0,
          endGoal: 1,
          unit: 'completed',
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
            depth: Value(taskDepth),
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

  // ── Drag-to-reparent ────────────────────────────────────────────────────────

  bool _canDropSubtaskOnMain(int dragIndex) {
    final dragged = _stateManager.getSubtask(dragIndex);
    return dragged != null && dragged.isExisting;
  }

  /// Drop on the main task card [P]: promote subtask [S] one level — same parent
  /// and depth as [P] (sibling of [P]). Subtree under [S] shifts by the depth delta.
  /// If [P] is at project root, [S] moves to root (parent null, depth 0).
  Future<void> _reparentOntoMainTask(int dragIndex) async {
    final dragged = _stateManager.getSubtask(dragIndex);
    if (dragged == null || !dragged.isExisting) return;

    await _moveToParent(
      dragIndex,
      newParentId: widget.task.parentTaskId,
      newDepth: widget.task.depth,
    );
  }

  /// When a subtask is dropped onto another subtask, reparent it under that
  /// target (the target becomes the new parent).
  Future<void> _reparentSubtask(int dragIndex, int targetIndex) async {
    final dragged = _stateManager.getSubtask(dragIndex);
    final target = _stateManager.getSubtask(targetIndex);
    if (dragged == null || target == null) return;
    if (!dragged.isExisting || !target.isExisting) return;
    // Don't reparent onto yourself
    if (dragIndex == targetIndex) return;

    final notifier = ref.read(
      projectTasksNotifier(widget.task.projectId).notifier,
    );

    // Fetch current depths from DB — state manager values may be stale
    final targetTask = await notifier.getTask(target.savedId);
    final draggedTask = await notifier.getTask(dragged.savedId);
    final newDepth = targetTask.depth + 1;
    final depthDelta = newDepth - draggedTask.depth;

    // Set the dragged task's parent to the target task
    await notifier.updateTaskSilent(
      dragged.savedId,
      TaskCompanion(
        parentTaskId: Value(target.savedId),
        depth: Value(newDepth),
      ),
    );

    // Shift entire subtree by the same delta
    if (depthDelta != 0) {
      final descendants = await notifier.getAllDescendants(dragged.savedId);
      for (final desc in descendants) {
        await notifier.updateTaskSilent(
          desc.id,
          TaskCompanion(depth: Value(desc.depth + depthDelta)),
        );
      }
    }

    // Single refresh after all writes
    await notifier.refresh();
    setState(() => isLoading = true);
    _initializeSubtasks();
  }

  // ── Navigation helpers ──────────────────────────────────────────────────────

  Future<void> _navigateToProject() async {
    final projectData = await ref
        .read(projectsNotifierProvider.notifier)
        .getProjectById(widget.task.projectId);
    if (projectData != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ProjectScreen(data: projectData)),
      );
    }
  }

  void _editTask(TaskData task) {
    showAddTaskDialog(
      context: context,
      projectId: task.projectId,
      taskData: task,
    ).then((_) {
      // Reload after edit
      setState(() => isLoading = true);
      _initializeSubtasks();
    });
  }

  // ── Build methods ───────────────────────────────────────────────────────────

  Widget _buildArrows() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: ArrowPainter(
            mainTaskKey: mainTaskKey,
            subtaskKeys: _stateManager.subtasks.map((s) => s.key).toList(),
            stackContext: context,
          ),
        ),
      ),
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
            MainTaskCard(
              task: task,
              cardKey: mainTaskKey,
              onEdit: () => _editTask(widget.task),
              onNavigateToProject: _navigateToProject,
              onDrop: _reparentMode ? _reparentOntoMainTask : null,
              onWillAcceptDrop: _reparentMode ? _canDropSubtaskOnMain : null,
            ),
            SizedBox(width: TaskBreakdownConstants.spacing),
            _buildSubtasksList(),
          ],
        ),
      ),
    );
  }

  Future<void> _moveToParent(
    int dragIndex, {
    required int? newParentId,
    required int newDepth,
  }) async {
    final dragged = _stateManager.getSubtask(dragIndex);
    if (dragged == null || !dragged.isExisting) return;

    final notifier = ref.read(
      projectTasksNotifier(widget.task.projectId).notifier,
    );

    final draggedTask = await notifier.getTask(dragged.savedId);
    if (!mounted) return;

    if (draggedTask.parentTaskId == newParentId &&
        draggedTask.depth == newDepth) {
      return;
    }

    final depthDelta = newDepth - draggedTask.depth;

    await notifier.updateTaskSilent(
      dragged.savedId,
      TaskCompanion(parentTaskId: Value(newParentId), depth: Value(newDepth)),
    );

    if (depthDelta != 0) {
      final descendants = await notifier.getAllDescendants(dragged.savedId);
      for (final desc in descendants) {
        await notifier.updateTaskSilent(
          desc.id,
          TaskCompanion(depth: Value(desc.depth + depthDelta)),
        );
      }
    }

    // Single refresh after all writes
    await notifier.refresh();
    setState(() => isLoading = true);
    _initializeSubtasks();
  }

  Widget _buildSubtasksList() {
    final subtasks = _stateManager.subtasks;
    return SizedBox(
      width: _dynamicSubtasksWidth,
      child: _reparentMode
          ? ReparentSubtaskList(
              subtasks: subtasks,
              parentTask: widget.task,
              subtasksWidth: _dynamicSubtasksWidth,
              onReparent: _reparentSubtask,
              onToggleSearch: _toggleSearchMode,
              onSelectExistingTask: _selectExistingTask,
              onRemove: _removeSubtask,
              onSaveNeeded: _saveSubtasks,
              onComplete: _handleTaskCompletion,
              onTextChanged: _handleTextChanged,
              onEdit: _editSubtask,
            )
          : ReorderSubtaskList(
              subtasks: subtasks,
              parentTask: widget.task,
              onReorder: (oldIndex, newIndex) {
                setState(
                  () => _stateManager.reorderSubtasks(oldIndex, newIndex),
                );
              },
              onToggleSearch: _toggleSearchMode,
              onSelectExistingTask: _selectExistingTask,
              onRemove: _removeSubtask,
              onSaveNeeded: _saveSubtasks,
              onComplete: _handleTaskCompletion,
              onTextChanged: _handleTextChanged,
              onEdit: _editSubtask,
            ),
    );
  }

  void _editSubtask(int index) async {
    final subtask = _stateManager.getSubtask(index);
    if (subtask == null || !subtask.isExisting) return;

    final task = await ref
        .read(projectTasksNotifier(widget.task.projectId).notifier)
        .getTask(subtask.savedId);
    if (!mounted) return;

    await showAddTaskDialog(
      context: context,
      projectId: task.projectId,
      taskData: task,
    );

    // Reload
    setState(() => isLoading = true);
    _initializeSubtasks();
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

  Widget _buildBottomActionBar(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.add),
                  label: const Text('Add subtask'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await _saveSubtasks();
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Depth: ${widget.task.depth}'),
        centerTitle: true,
        actions: [
          Tooltip(
            message: _reparentMode
                ? 'Switch to reorder mode'
                : 'Switch to reparent mode',
            child: IconButton(
              icon: Icon(
                _reparentMode ? Icons.reorder : Icons.account_tree_outlined,
                color: _reparentMode ? Colors.deepPurple : null,
              ),
              onPressed: () => setState(() => _reparentMode = !_reparentMode),
            ),
          ),
          _buildShowCompletedSwitch(),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              primary: false,
                              child: SizedBox(
                                width: _dynamicTotalWidth,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    _buildTaskBreakdownScreen(widget.task),
                                    _buildArrows(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildBottomActionBar(context),
              ],
            ),
    );
  }
}
