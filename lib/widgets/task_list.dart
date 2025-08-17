import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

enum TaskListViewState { initial, addingTasks }

class TaskList extends ConsumerStatefulWidget {
  final ProjectData? project;
  const TaskList({super.key, required this.project});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  TaskListViewState viewState = TaskListViewState.initial;
  List<TaskData> tasks = List.empty();
  List<bool Function(TaskData)> predicates = <bool Function(TaskData)>[];

  Widget _buildInitialView(BuildContext context) {
    return Column(
      children: [
        const Text('Select Tasks'),
        IconButton(
          onPressed: widget.project != null
              ? () {
                  setState(() {
                    viewState = TaskListViewState.addingTasks;
                    predicates = <bool Function(TaskData)>[
                      (task) => task.projectId == widget.project?.id,
                    ];
                  });
                }
              : null,
          icon: const Icon(Icons.add),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildAddTasksView(BuildContext context) {
    final taskNameController = TextEditingController();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 300, maxHeight: 300),
      child: Column(
        children: [
          SearchTextField(
            controller: taskNameController,
            labelText: 'Search Project Tasks',
            searchProvider: taskSearchProvider,
            getDisplayText: (task) => task.name,
            predicates: predicates,
          ),
          Expanded(
            child: ListView(
              children: tasks.map((task) => Text(task.name)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (viewState) {
      TaskListViewState.initial => _buildInitialView(context),
      TaskListViewState.addingTasks => _buildAddTasksView(context),
    };
  }
}
