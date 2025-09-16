import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';

class TaskBreakdownScreen extends ConsumerStatefulWidget {
  final TaskData task;

  const TaskBreakdownScreen({super.key, required this.task});

  @override
  ConsumerState<TaskBreakdownScreen> createState() => _TaskBreakdownScreenState();
}

class _TaskBreakdownScreenState extends ConsumerState<TaskBreakdownScreen> {
  late List<TextEditingController> subtasks;
  late List<bool> isExistingSubtask; 

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final subtasksData = await ref.read(projectTasksNotifier(widget.task.projectId).notifier).getSubtasks(widget.task.id);
      setState(() {
        if (subtasksData.isEmpty) {
          subtasks = [TextEditingController()];
          isExistingSubtask = [false];
        } else {
          subtasks = subtasksData.map((subt) => TextEditingController(text: subt.name)).toList();
          isExistingSubtask = List.generate(subtasksData.length, (index) => true); 
        }
      });
    });

  }

  void _addSubtask() {
    setState(() {
      subtasks.add(TextEditingController());
      isExistingSubtask.add(false); 
    });
  }

  void _saveSubtasks() async {
    var notifier = ref.read(projectTasksNotifier(widget.task.projectId).notifier);
    final date = ref.read(dateNotifierProvider).toDateTimeUnspecified();

    for (int i = 0; i < subtasks.length; i++) {
      final subtask = subtasks[i];
      notifier.addTask(subtask.text.trim(), widget.task.projectId, date, parentTaskId: widget.task.id, depth: widget.task.depth+1, orderIndex: i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Task Breakdown'),
      ),
      body: _buildTaskBreakdownScreen(widget.task),
      floatingActionButton: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          FloatingActionButton(
            onPressed: subtasks.length < 5 ? _addSubtask : null,
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 16), 
          FloatingActionButton(
            onPressed: () => _saveSubtasks(),
            child: const Icon(Icons.save),
          ),
        ],)
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      task.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
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
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: subtasks.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextField(
                              controller: subtasks[index],
                              readOnly: isExistingSubtask[index],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Subtask ${index + 1}',
                                fillColor: isExistingSubtask[index] ? Colors.grey : null,
                                filled: isExistingSubtask[index]
                              ),
                            ),
                          ),
                        );
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