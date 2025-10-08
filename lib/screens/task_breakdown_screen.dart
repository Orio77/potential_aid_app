import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
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
  List<TextEditingController> subtasks = [];
  List<bool> isExistingSubtask = [];
  List<GlobalKey> subtaskKeys = [];
  List<FocusNode> subtaskFocusNodes = [];
  List<int> subtasksOfSubtasksCount = [];
  List<int> savedIds = [];
  List<bool> isSearchMode = [];
  List<TextEditingController> searchControllers = [];
  List<FocusNode> searchFocusNodes = [];
  final GlobalKey mainTaskKey = GlobalKey();
  bool isLoading = true;

  static const double mainTaskWidth = 160.0;
  static const double subtasksWidth = 260.0;
  static const double spacing = 8.0;
  static const double padding = 8.0;

  double _dynamicTotalWidth = mainTaskWidth + subtasksWidth + spacing + padding;
  double _dynamicSubtasksWidth = subtasksWidth;

  @override
  void initState() {
    super.initState();
    _initializeSubtasks();
  }

  @override
  void dispose() {
    // Dispose all focus nodes and controllers
    for (var controller in searchControllers) {
      controller.dispose();
    }
    for (var focusNode in subtaskFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in searchFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _initializeSubtasks() async {
    final subtasksData = await ref
        .read(projectTasksNotifier(widget.task.projectId).notifier)
        .getSubtasks(widget.task.id);
    for (final subtask in subtasksData) {
      final subtasksOfSubtaskData = await ref
          .read(projectTasksNotifier(subtask.projectId).notifier)
          .getSubtasks(subtask.id);
      subtasksOfSubtasksCount.add(subtasksOfSubtaskData.length);
    }
    setState(() {
      if (subtasksData.isEmpty) {
        subtasks = [TextEditingController()];
        isExistingSubtask = [false];
        subtaskKeys = [GlobalKey()];
        subtaskFocusNodes = [FocusNode()];
        savedIds = [-1]; // Initialize with -1 for new subtask
        subtasksOfSubtasksCount = [0];
        // Initialize search-related lists for empty state
        isSearchMode = [false];
        searchControllers = [TextEditingController()];
        searchFocusNodes = [FocusNode()];
      } else {
        subtasks = subtasksData
            .map((subt) => TextEditingController(text: subt.name))
            .toList();
        isExistingSubtask = List.generate(subtasksData.length, (index) => true);
        subtaskKeys = List.generate(
          subtasksData.length,
          (index) => GlobalKey(),
        );
        subtaskFocusNodes = List.generate(
          subtasksData.length,
          (index) => FocusNode(),
        );
        savedIds = subtasksData.map((subt) => subt.id).toList();
        isSearchMode = List.generate(subtasksData.length, (index) => false);
        searchControllers = List.generate(
          subtasksData.length,
          (index) => TextEditingController(),
        );
        searchFocusNodes = List.generate(
          subtasksData.length,
          (index) => FocusNode(),
        );
      }
      _dynamicTotalWidth = _calculateDynamicWidth();
      isLoading = false;
    });
  }

  void _addSubtask() {
    setState(() {
      subtasks.add(TextEditingController());
      isExistingSubtask.add(false);
      subtaskKeys.add(GlobalKey());
      subtaskFocusNodes.add(FocusNode());
      savedIds.add(-1);
      subtasksOfSubtasksCount.add(0);
      isSearchMode.add(false);
      searchControllers.add(TextEditingController());
      searchFocusNodes.add(FocusNode());
    });

    // Focus on the newly added subtask after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newIndex = subtasks.length - 1;
      if (newIndex >= 0 && newIndex < subtaskFocusNodes.length) {
        subtaskFocusNodes[newIndex].requestFocus();
      }
    });
  }

  void _toggleSearchMode(int index) {
    setState(() {
      isSearchMode[index] = !isSearchMode[index];
      if (isSearchMode[index]) {
        searchControllers[index].clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchFocusNodes[index].requestFocus();
        });
      } else {
        searchControllers[index].clear();
      }
    });
  }

  void _selectExistingTask(int index, TaskData selectedTask) {
    setState(() {
      subtasks[index].text = selectedTask.name;

      isExistingSubtask[index] = true;
      savedIds[index] = selectedTask.id;

      _updateSubtaskCount(index, selectedTask.id);

      isSearchMode[index] = false;
      searchControllers[index].clear();

      _dynamicTotalWidth = _calculateDynamicWidth();
    });
  }

  void _correctIndexes(int index) {
    if (index >= subtasks.length ||
        index >= subtaskFocusNodes.length ||
        index >= isExistingSubtask.length ||
        index >= subtaskKeys.length ||
        index >= savedIds.length ||
        index >= searchControllers.length ||
        index >= searchFocusNodes.length ||
        index >= isSearchMode.length) {
      return;
    }

    setState(() {
      subtaskFocusNodes[index].dispose();
      searchControllers[index].dispose();
      searchFocusNodes[index].dispose();

      subtasks.removeAt(index);
      isExistingSubtask.removeAt(index);
      subtaskKeys.removeAt(index);
      subtaskFocusNodes.removeAt(index);
      savedIds.removeAt(index);
      subtasksOfSubtasksCount.removeAt(index);
      isSearchMode.removeAt(index);
      searchControllers.removeAt(index);
      searchFocusNodes.removeAt(index);
    });
  }

  double _calculateDynamicWidth() {
    double maxSubtaskWidth = subtasksWidth;

    for (final controller in subtasks) {
      if (controller.text.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: controller.text,
            style: const TextStyle(fontSize: 17),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final neededWidth = textPainter.width + 155;
        maxSubtaskWidth = max(maxSubtaskWidth, neededWidth);
      }
    }

    _dynamicSubtasksWidth = maxSubtaskWidth;

    double dynamicMainTaskWidth = mainTaskWidth;
    final taskTextPainter = TextPainter(
      text: TextSpan(
        text: widget.task.name,
        style: const TextStyle(fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    );
    taskTextPainter.layout();
    final neededMainWidth = taskTextPainter.width + 60;
    dynamicMainTaskWidth = max(dynamicMainTaskWidth, neededMainWidth);

    return dynamicMainTaskWidth + maxSubtaskWidth + spacing + padding;
  }

  Future<void> _saveSubtasks() async {
    var notifier = ref.read(
      projectTasksNotifier(widget.task.projectId).notifier,
    );
    final date = ref.read(dateNotifierProvider).toDateTimeUnspecified();

    for (int i = 0; i < subtasks.length; i++) {
      if (i >= isExistingSubtask.length || i >= savedIds.length) {
        break;
      }

      final taskDepth = widget.task.depth + 1;

      if (!isExistingSubtask[i] && savedIds[i] == -1) {
        final subtask = subtasks[i];
        if (subtask.text.trim().isNotEmpty) {
          final taskId = await notifier.addTask(
            subtask.text.trim(),
            widget.task.projectId,
            date,
            parentTaskId: widget.task.id,
            depth: taskDepth,
            orderIndex: i,
          );
          setState(() {
            // Check bounds again before setting
            if (i < savedIds.length && i < isExistingSubtask.length) {
              savedIds[i] = taskId;
              isExistingSubtask[i] = true;
            }
          });
        }
      } else if (isExistingSubtask[i]) {
        final taskId = savedIds[i];
        await notifier.updateTask(
          taskId,
          TaskCompanion(parentTaskId: Value(widget.task.id)),
        );
      }

      ref.invalidate(taskCardsNotifierProvider(taskDepth));
    }
  }

  Future<void> _updateSubtaskCount(int index, int taskId) async {
    final subtasksOfTask = await ref
        .read(projectTasksNotifier(widget.task.projectId).notifier)
        .getSubtasks(taskId);
    setState(() {
      if (index < subtasksOfSubtasksCount.length) {
        subtasksOfSubtasksCount[index] = subtasksOfTask.length;
      }
    });
  }

  Future<void> _deleteParentTaskFromSubtasks(int index) async {
    final taskId = savedIds[index];
    await ref
        .read(projectTasksNotifier(widget.task.projectId).notifier)
        .updateTask(taskId, TaskCompanion(parentTaskId: Value(null)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Depth: ${widget.task.depth}'),
        centerTitle: true,
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
                  onPressed: () async => await _saveSubtasks(),
                  child: const Icon(Icons.save),
                ),
              ],
            ),
    );
  }

  Widget _buildArrows() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: ArrowPainter(
            mainTaskKey: mainTaskKey,
            subtaskKeys: subtaskKeys,
            stackContext: context,
          ),
          size: Size(_dynamicTotalWidth, double.infinity),
        );
      },
    );
  }

  Widget _buildBreakdownSubtaskButton(int index) {
    final navigator = Navigator.of(context);

    return IconButton(
      onPressed: () async {
        if (index >= savedIds.length) return;

        if (savedIds[index] != -1) {
          final subtask = await ref
              .read(projectTasksNotifier(widget.task.projectId).notifier)
              .getTask(savedIds[index]);
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => TaskBreakdownScreen(task: subtask),
            ),
          );
        } else {
          await _saveSubtasks();
          if (index < savedIds.length && savedIds[index] != -1) {
            final subtask = await ref
                .read(projectTasksNotifier(widget.task.projectId).notifier)
                .getTask(savedIds[index]);
            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (context) => TaskBreakdownScreen(task: subtask),
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
        if (isExistingSubtask[index]) {
          await _deleteParentTaskFromSubtasks(index);
        }
        _correctIndexes(index);
      },
      icon: Icon(Icons.delete),
    );
  }

  Widget _buildSubtaskCountInfo(int index) {
    return Padding(
      padding: EdgeInsets.fromLTRB(3, 0, 0, 0),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Center(
          child: Text(
            subtasksOfSubtasksCount.length > index
                ? subtasksOfSubtasksCount[index].toString()
                : "0",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(int index) {
    return SearchTextField<TaskData, TaskSearchNotifier>(
      controller: searchControllers[index],
      focusNode: searchFocusNodes[index],
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
        (task) => !savedIds.contains(task.id), // Not already added
      ],
      maxResults: 5,
    );
  }

  Widget _buildTaskBreakdownScreen(TaskData task) {
    return SizedBox(
      width: _dynamicTotalWidth,
      child: Padding(
        padding: EdgeInsets.all(padding / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: mainTaskWidth,
              child: Center(
                child: Card(
                  key: mainTaskKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 200.0,
                        minHeight: 60.0,
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
            SizedBox(width: spacing),
            SizedBox(
              width: _dynamicSubtasksWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount: subtasks.length,
                      itemBuilder: (context, index) {
                        // Comprehensive bounds checking to prevent RangeError
                        if (index >= subtasks.length ||
                            index >= subtaskKeys.length ||
                            index >= subtaskFocusNodes.length ||
                            index >= isExistingSubtask.length ||
                            index >= isSearchMode.length ||
                            index >= searchControllers.length ||
                            index >= searchFocusNodes.length) {
                          return const SizedBox.shrink();
                        }

                        return Card(
                          key: subtaskKeys[index],
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: isSearchMode[index]
                                      ? _buildSearchField(index)
                                      : GestureDetector(
                                          onLongPress: () =>
                                              _toggleSearchMode(index),
                                          child: TextField(
                                            controller: subtasks[index],
                                            focusNode: subtaskFocusNodes[index],
                                            readOnly: isExistingSubtask[index],
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                              hintText: 'Subtask ${index + 1}',
                                              fillColor:
                                                  isExistingSubtask[index]
                                                  ? Colors.grey
                                                  : null,
                                              filled: isExistingSubtask[index],
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                _dynamicTotalWidth =
                                                    _calculateDynamicWidth();
                                              });
                                            },
                                          ),
                                        ),
                                ),
                                _buildSubtaskCountInfo(index),
                                _buildBreakdownSubtaskButton(index),
                                _buildRemoveSubtaskButton(index),
                              ],
                            ),
                          ),
                        );
                      },
                      onReorder: (oldIndex, newIndex) {
                        if (isExistingSubtask.length >= oldIndex &&
                                isExistingSubtask[oldIndex] ||
                            isExistingSubtask.length >= newIndex &&
                                isExistingSubtask[newIndex]) {
                          null;
                        } else {
                          setState(() {
                            final adjustedIndex = newIndex > oldIndex
                                ? newIndex - 1
                                : newIndex;

                            final TextEditingController movedController =
                                subtasks.removeAt(oldIndex);
                            final bool movedExisting = isExistingSubtask
                                .removeAt(oldIndex);
                            final GlobalKey movedKey = subtaskKeys.removeAt(
                              oldIndex,
                            );
                            final FocusNode movedFocusNode = subtaskFocusNodes
                                .removeAt(oldIndex);
                            final int movedSavedId = savedIds.removeAt(
                              oldIndex,
                            );
                            final int movedSavedSubtaskCount =
                                subtasksOfSubtasksCount.removeAt(oldIndex);

                            subtasks.insert(adjustedIndex, movedController);
                            isExistingSubtask.insert(
                              adjustedIndex,
                              movedExisting,
                            );
                            subtaskKeys.insert(adjustedIndex, movedKey);
                            subtaskFocusNodes.insert(
                              adjustedIndex,
                              movedFocusNode,
                            );
                            savedIds.insert(adjustedIndex, movedSavedId);
                            subtasksOfSubtasksCount.insert(
                              adjustedIndex,
                              movedSavedSubtaskCount,
                            );
                            isSearchMode.insert(
                              adjustedIndex,
                              isSearchMode.removeAt(oldIndex),
                            );
                            searchControllers.insert(
                              adjustedIndex,
                              searchControllers.removeAt(oldIndex),
                            );
                            searchFocusNodes.insert(
                              adjustedIndex,
                              searchFocusNodes.removeAt(oldIndex),
                            );
                          });
                        }
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
}
