import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';

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
  List<int> savedIds = [];
  final GlobalKey mainTaskKey = GlobalKey();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeSubtasks();
  }

  void _initializeSubtasks() async {
    final subtasksData = await ref
        .read(projectTasksNotifier(widget.task.projectId).notifier)
        .getSubtasks(widget.task.id);
    setState(() {
      if (subtasksData.isEmpty) {
        subtasks = [TextEditingController()];
        isExistingSubtask = [false];
        subtaskKeys = [GlobalKey()];
        savedIds = [-1]; // Initialize with -1 for new subtask
      } else {
        subtasks = subtasksData
            .map((subt) => TextEditingController(text: subt.name))
            .toList();
        isExistingSubtask = List.generate(subtasksData.length, (index) => true);
        subtaskKeys = List.generate(
          subtasksData.length,
          (index) => GlobalKey(),
        );
        savedIds = subtasksData.map((subt) => subt.id).toList();
      }
      isLoading = false;
    });
  }

  void _addSubtask() {
    setState(() {
      subtasks.add(TextEditingController());
      isExistingSubtask.add(false);
      subtaskKeys.add(GlobalKey());
      savedIds.add(-1);
    });
  }

  Future<void> _saveSubtasks() async {
    var notifier = ref.read(
      projectTasksNotifier(widget.task.projectId).notifier,
    );
    final date = ref.read(dateNotifierProvider).toDateTimeUnspecified();

    for (int i = 0; i < subtasks.length; i++) {
      if (!isExistingSubtask[i] && savedIds[i] == -1) {
        final subtask = subtasks[i];
        if (subtask.text.trim().isNotEmpty) {
          final taskId = await notifier.addTask(
            subtask.text.trim(),
            widget.task.projectId,
            date,
            parentTaskId: widget.task.id,
            depth: widget.task.depth + 1,
            orderIndex: i,
          );
          setState(() {
            savedIds[i] = taskId;
            isExistingSubtask[i] = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Task Breakdown'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                _buildTaskBreakdownScreen(widget.task),
                if (!isLoading) IgnorePointer(child: _buildArrows()),
              ],
            ),
      floatingActionButton: isLoading
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "add_subtask",
                  onPressed: subtasks.length < 5 ? _addSubtask : null,
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
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildBreakdownSubtaskButton(int index) {
    final navigator = Navigator.of(context);

    return IconButton(
      onPressed: () async {
        if (savedIds[index] != -1) {
          final subtask = await ref
              .read(projectTasksNotifier(widget.task.projectId).notifier)
              .getTask(savedIds[index]);
          // Replace current screen instead of pushing
          navigator.pushReplacement(
            MaterialPageRoute(
              builder: (context) => TaskBreakdownScreen(task: subtask),
            ),
          );
        } else {
          await _saveSubtasks();
          if (savedIds[index] != -1) {
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
        // Replace current screen instead of pushing
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
      onPressed: () {
        setState(() {
          subtasks.removeAt(index);
          isExistingSubtask.removeAt(index);
          subtaskKeys.removeAt(index);
          savedIds.removeAt(index);
        });
      },
      icon: Icon(Icons.delete),
    );
  }

  Widget _buildTaskBreakdownScreen(TaskData task) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Card(
                key: mainTaskKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.task.parentTaskId != null) ...[
                        _buildGoToParentTaskButton(),
                      ],

                      Text(
                        task.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    itemCount: subtasks.length,
                    itemBuilder: (context, index) {
                      return Card(
                        key: subtaskKeys[index],
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: subtasks[index],
                                  readOnly: isExistingSubtask[index],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Subtask ${index + 1}',
                                    fillColor: isExistingSubtask[index]
                                        ? Colors.grey
                                        : null,
                                    filled: isExistingSubtask[index],
                                  ),
                                ),
                              ),
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

                          final TextEditingController movedController = subtasks
                              .removeAt(oldIndex);
                          final bool movedExisting = isExistingSubtask.removeAt(
                            oldIndex,
                          );
                          final GlobalKey movedKey = subtaskKeys.removeAt(
                            oldIndex,
                          );
                          final int movedSavedId = savedIds.removeAt(oldIndex);

                          subtasks.insert(adjustedIndex, movedController);
                          isExistingSubtask.insert(
                            adjustedIndex,
                            movedExisting,
                          );
                          subtaskKeys.insert(adjustedIndex, movedKey);
                          savedIds.insert(adjustedIndex, movedSavedId);
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
    );
  }
}

class ArrowPainter extends CustomPainter {
  final GlobalKey mainTaskKey;
  final List<GlobalKey> subtaskKeys;
  final BuildContext stackContext;

  ArrowPainter({
    required this.mainTaskKey,
    required this.subtaskKeys,
    required this.stackContext,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurpleAccent.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = Colors.deepPurpleAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Get main task position
    final mainTaskRenderBox =
        mainTaskKey.currentContext?.findRenderObject() as RenderBox?;
    if (mainTaskRenderBox == null) return;

    // Get the Stack's render box for coordinate conversion
    final stackRenderBox = stackContext.findRenderObject() as RenderBox?;
    if (stackRenderBox == null) return;

    // Convert main task position to Stack's coordinate system
    final mainTaskGlobalPosition = mainTaskRenderBox.localToGlobal(Offset.zero);
    final mainTaskLocalPosition = stackRenderBox.globalToLocal(
      mainTaskGlobalPosition,
    );
    final mainTaskSize = mainTaskRenderBox.size;

    // Start point: right edge, center of main task
    final startPoint = Offset(
      mainTaskLocalPosition.dx + mainTaskSize.width,
      mainTaskLocalPosition.dy + mainTaskSize.height / 2,
    );

    // Draw arrows to each subtask
    for (final subtaskKey in subtaskKeys) {
      // Check if the element is still mounted and active
      final context = subtaskKey.currentContext;
      if (context == null || !context.mounted) continue;

      final subtaskRenderBox = context.findRenderObject() as RenderBox?;
      if (subtaskRenderBox == null || !subtaskRenderBox.hasSize) continue;

      // Convert subtask position to Stack's coordinate system
      final subtaskGlobalPosition = subtaskRenderBox.localToGlobal(Offset.zero);
      final subtaskLocalPosition = stackRenderBox.globalToLocal(
        subtaskGlobalPosition,
      );
      final subtaskSize = subtaskRenderBox.size;

      // End point: left edge, center of subtask
      final endPoint = Offset(
        subtaskLocalPosition.dx,
        subtaskLocalPosition.dy + subtaskSize.height / 2,
      );

      // Only draw if there's a meaningful distance
      if ((endPoint.dx - startPoint.dx).abs() < 10) continue;

      // Draw curved line
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);

      // Create smoother curve control points
      final horizontalDistance = endPoint.dx - startPoint.dx;

      final controlPoint1 = Offset(
        startPoint.dx + horizontalDistance * 0.6,
        startPoint.dy,
      );
      final controlPoint2 = Offset(
        startPoint.dx + horizontalDistance * 0.4,
        endPoint.dy,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );

      canvas.drawPath(path, paint);

      _drawArrowhead(canvas, arrowPaint, endPoint);
    }
  }

  void _drawArrowhead(Canvas canvas, Paint paint, Offset tip) {
    const arrowSize = 10.0;
    final path = Path();

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(tip.dx - arrowSize, tip.dy - arrowSize / 2);
    path.lineTo(tip.dx - arrowSize, tip.dy + arrowSize / 2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
