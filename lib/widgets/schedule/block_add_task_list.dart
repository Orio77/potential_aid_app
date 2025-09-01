import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

class BlockAddTaskList extends ConsumerStatefulWidget {
  final ProjectData? project;
  final List<TaskData>? initialTasks;
  final void Function(List<TaskData>) onTasksChanged;
  const BlockAddTaskList({
    super.key,
    required this.project,
    this.initialTasks,
    required this.onTasksChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<BlockAddTaskList> {
  late List<TaskData> _tasks;
  List<bool Function(TaskData)> _predicates = <bool Function(TaskData)>[];
  late final TextEditingController _taskNameController;

  @override
  void initState() {
    super.initState();
    _tasks = widget.initialTasks ?? <TaskData>[];
    _taskNameController = TextEditingController();
    _updatePredicates();
  }

  @override
  void didUpdateWidget(BlockAddTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.project?.id != oldWidget.project?.id) {
      setState(() {
        _tasks.clear();
        _taskNameController.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTasksChanged(_tasks);
      });
      _updatePredicates();
    }
  }

  void _updatePredicates() {
    _predicates = widget.project != null
        ? [(task) => task.projectId == widget.project!.id]
        : [];
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  Widget _buildAddTasksView(BuildContext context) {
    return Column(
      children: [
        SearchTextField(
          controller: _taskNameController,
          labelText: 'Search Project Tasks',
          searchProvider: taskSearchProvider,
          onItemSelected: (task) => _addTaskToList(task),
          getDisplayText: (task) => task.name,
          predicates: _predicates,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _tasks.isEmpty
              ? const Center(child: Text('No tasks selected'))
              : ListView.builder(
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return ListTile(
                      title: Text(task.name),
                      trailing: IconButton(
                        onPressed: () => _removeTaskFromList(index),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addTaskToList(TaskData task) {
    if (!_tasks.any((existingTask) => existingTask.id == task.id)) {
      setState(() {
        _tasks.add(task);
        _taskNameController.clear();
      });
      widget.onTasksChanged(_tasks);
    }
  }

  void _removeTaskFromList(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    widget.onTasksChanged(_tasks);
  }

  @override
  Widget build(BuildContext context) {
    return widget.project != null
        ? _buildAddTasksView(context)
        : SizedBox.shrink();
  }
}
