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

  Future<void> _deleteParentTaskFromSubtasks(int index) async {
    final subtask = _stateManager.getSubtask(index);
    if (subtask != null && subtask.savedId != -1) {
      await ref
          .read(projectTasksNotifier(widget.task.projectId).notifier)
          .updateTask(
            subtask.savedId,
            TaskCompanion(parentTaskId: Value(null), depth: Value(0)),
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

  // ── Drag-to-reparent ────────────────────────────────────────────────────────

  /// When a subtask is dropped onto another subtask, reparent it under that
  /// target (the target becomes the new parent).
  Future<void> _reparentSubtask(int dragIndex, int targetIndex) async {
    final dragged = _stateManager.getSubtask(dragIndex);
    final target = _stateManager.getSubtask(targetIndex);
    if (dragged == null || target == null) return;
    if (!dragged.isExisting || !target.isExisting) return;
    // Don't reparent onto yourself
    if (dragIndex == targetIndex) return;

    final notifier =
        ref.read(projectTasksNotifier(widget.task.projectId).notifier);

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
        MaterialPageRoute(
          builder: (_) => ProjectScreen(data: projectData),
        ),
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
            _reparentMode
                ? _buildMainTaskCardAsDropTarget(task)
                : _buildMainTaskCard(task),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: 'Edit task',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _editTask(widget.task),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.folder_open, size: 18),
                          tooltip: 'Go to project',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _navigateToProject,
                        ),
                      ],
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

  /// Main task card wrapped as a DragTarget in reparent mode.
  /// Dropping a subtask here sets its parent to widget.task.id — same level
  /// as its current siblings (depth unchanged relative to this screen).
  Widget _buildMainTaskCardAsDropTarget(TaskData task) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) =>
          _promoteToSibling(details.data),
      builder: (context, candidateData, _) {
        final hovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: hovered
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple, width: 2),
                  color: Colors.deepPurple.withValues(alpha: 0.06),
                )
              : null,
          child: _buildMainTaskCard(task),
        );
      },
    );
  }

  /// Promotes the subtask at [dragIndex] to be a sibling of widget.task —
  /// i.e. parentTaskId = widget.task.parentTaskId, depth = widget.task.depth.
  /// If widget.task is already depth 0 this is the same as _promoteToRoot.
  Future<void> _promoteToSibling(int dragIndex) async {
    if (widget.task.depth == 0) {
      await _promoteToRoot(dragIndex);
      return;
    }
    await _moveToParent(
      dragIndex,
      newParentId: widget.task.parentTaskId,
      newDepth: widget.task.depth,
    );
  }

  /// Detaches the subtask from all parents — becomes a root task in the project
  /// (parentTaskId = null, depth = 0).
  Future<void> _promoteToRoot(int dragIndex) async {
    await _moveToParent(dragIndex, newParentId: null, newDepth: 0);
  }

  Future<void> _moveToParent(
    int dragIndex, {
    required int? newParentId,
    required int newDepth,
  }) async {
    final dragged = _stateManager.getSubtask(dragIndex);
    if (dragged == null || !dragged.isExisting) return;

    final notifier =
        ref.read(projectTasksNotifier(widget.task.projectId).notifier);

    final draggedTask = await notifier.getTask(dragged.savedId);
    final depthDelta = newDepth - draggedTask.depth;

    await notifier.updateTaskSilent(
      dragged.savedId,
      TaskCompanion(
        parentTaskId: Value(newParentId),
        depth: Value(newDepth),
      ),
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
    return SizedBox(
      width: _dynamicSubtasksWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: _reparentMode
                ? _buildReparentList()
                : _buildReorderList(),
          ),
        ],
      ),
    );
  }

  // ── Reorder mode (default) ──────────────────────────────────────────────────

  Widget _buildReorderList() {
    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      itemCount: _stateManager.subtasks.length,
      itemBuilder: (context, index) {
        final subtask = _stateManager.getSubtask(index);
        if (subtask == null) {
          return SizedBox.shrink(key: ValueKey('empty_$index'));
        }
        return Row(
          key: Key(subtask.id),
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
              ),
            ),
            Expanded(
              child: SubtaskCard(
                subtask: subtask,
                index: index,
                parentTask: widget.task,
                onToggleSearch: _toggleSearchMode,
                onSelectExistingTask: _selectExistingTask,
                onRemove: _removeSubtask,
                onSaveNeeded: _saveSubtasks,
                onComplete: _handleTaskCompletion,
                onTextChanged: _handleTextChanged,
                onEdit: _editSubtask,
              ),
            ),
          ],
        );
      },
      onReorder: (oldIndex, newIndex) {
        setState(() => _stateManager.reorderSubtasks(oldIndex, newIndex));
      },
    );
  }

  // ── Reparent mode ───────────────────────────────────────────────────────────

  Widget _buildProjectRootDropZone() {
    return DragTarget<int>(
      key: const ValueKey('project_root_drop'),
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => _promoteToRoot(d.data),
      builder: (context, candidateData, _) {
        final hovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hovered ? Colors.orange : Colors.grey.shade400,
              width: hovered ? 2 : 1,
            ),
            color: hovered
                ? Colors.orange.withValues(alpha: 0.10)
                : Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Icon(
                Icons.drive_file_move_outline,
                size: 18,
                color: hovered ? Colors.orange : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Move to project root (depth 0)',
                style: TextStyle(
                  fontSize: 13,
                  color: hovered ? Colors.orange.shade800 : Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReparentList() {
    final subtasks = _stateManager.subtasks;
    return ListView.builder(
      shrinkWrap: true,
      // +1 for the project-root drop zone at index 0
      itemCount: subtasks.length + 1,
      itemBuilder: (context, index) {
        // Index 0 is the project-root drop zone
        if (index == 0) return _buildProjectRootDropZone();

        final realIndex = index - 1;
        final subtask = _stateManager.getSubtask(realIndex);
        if (subtask == null) return const SizedBox.shrink();

        final card = SubtaskCard(
          subtask: subtask,
          index: realIndex,
          parentTask: widget.task,
          onToggleSearch: _toggleSearchMode,
          onSelectExistingTask: _selectExistingTask,
          onRemove: _removeSubtask,
          onSaveNeeded: _saveSubtasks,
          onComplete: _handleTaskCompletion,
          onTextChanged: _handleTextChanged,
          onEdit: _editSubtask,
        );

        return DragTarget<int>(
          key: Key(subtask.id),
          onWillAcceptWithDetails: (d) => d.data != realIndex && subtask.isExisting,
          onAcceptWithDetails: (d) => _reparentSubtask(d.data, realIndex),
          builder: (context, candidateData, _) {
            final hovered = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: hovered
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple, width: 2),
                      color: Colors.deepPurple.withValues(alpha: 0.06),
                    )
                  : null,
              child: LongPressDraggable<int>(
                data: realIndex,
                delay: const Duration(milliseconds: 300),
                feedback: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: _dynamicSubtasksWidth * 0.85,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple),
                    ),
                    child: Text(
                      subtask.controller.text,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: card),
                child: card,
              ),
            );
          },
        );
      },
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
        actions: [
          Tooltip(
            message: _reparentMode ? 'Switch to reorder mode' : 'Switch to reparent mode',
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
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: _dynamicTotalWidth,
                child: Stack(
                  children: [
                    _buildTaskBreakdownScreen(widget.task),
                    if (!isLoading) _buildArrows(),
                  ],
                ),
              ),
            ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }
}
