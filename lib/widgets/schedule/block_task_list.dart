import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

enum TaskListViewState { initial, addingTasks }

class BlockTaskList extends ConsumerStatefulWidget {
  final ProjectData? project;
  final void Function(List<TaskData>) onTasksChanged;
  const BlockTaskList({
    super.key,
    required this.project,
    required this.onTasksChanged,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<BlockTaskList> {
  TaskListViewState viewState = TaskListViewState.initial;
  final List<TaskData> _tasks = <TaskData>[];
  List<bool Function(TaskData)> _predicates = <bool Function(TaskData)>[];
  late final TextEditingController _taskNameController;

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController();
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    super.dispose();
  }

  Widget _buildInitialView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Select Tasks'),
        IconButton(
          onPressed: widget.project != null ? _onAddTaskPressed : null,
          icon: const Icon(Icons.add),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildAddTasksView(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
      child: Column(
        children: [
          SearchTextField(
            controller: _taskNameController,
            labelText: 'Search Project Tasks',
            searchProvider: taskSearchProvider,
            onItemSelected: (task) => _addTaskToList(task),
            getDisplayText: (task) => task.name,
            predicates: _predicates,
          ),
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
      ),
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

  void _onAddTaskPressed() {
    {
      setState(() {
        viewState = TaskListViewState.addingTasks;
        _predicates = <bool Function(TaskData)>[
          (task) => task.projectId == widget.project?.id,
        ];
      });
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
    return switch (viewState) {
      TaskListViewState.initial => _buildInitialView(context),
      TaskListViewState.addingTasks => _buildAddTasksView(context),
    };
  }
}
