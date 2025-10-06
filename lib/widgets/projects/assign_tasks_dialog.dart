import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/providers/project_search_notifier.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';

class AssignTasksToProjectDialog extends ConsumerStatefulWidget {
  final List<TaskData> tasksToAssign;
  final int projectId;
  const AssignTasksToProjectDialog({
    super.key,
    required this.tasksToAssign,
    required this.projectId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AssignTasksToProjectDialogState();
}

class _AssignTasksToProjectDialogState
    extends ConsumerState<AssignTasksToProjectDialog> {
  ProjectData? selectedProject;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return AlertDialog(
      title: Text('Assign Tasks to Project'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            SearchTextField<ProjectData, ProjectSearchNotifier>(
              labelText: "Search Projects",
              searchProvider: projectSearchProvider,
              getDisplayText: (project) => project.name,
              onItemSelected: (project) => setState(() {
                selectedProject = project;
              }),
            ),
            if (selectedProject != null)
              Card(
                child: ListTile(
                  title: Text('Selected: ${selectedProject!.name}'),
                  trailing: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => setState(() {
                      selectedProject = null;
                    }),
                  ),
                ),
              ),
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: widget.tasksToAssign.length,
                  itemBuilder: (context, index) {
                    final task = widget.tasksToAssign[index];
                    return ListTile(
                      leading: Icon(Icons.task_alt_rounded),
                      title: Text(task.name, overflow: TextOverflow.ellipsis),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: selectedProject != null
              ? () async {
                  final notifier = ref.read(
                    projectTasksNotifier(widget.projectId).notifier,
                  );

                  for (final task in widget.tasksToAssign) {
                    // Get all descendants recursively
                    final allDescendants = await notifier.getAllDescendants(
                      task.id,
                    );

                    // Update the main task
                    await notifier.updateTask(
                      task.id,
                      TaskCompanion(
                        projectId: Value(selectedProject!.id),
                        parentTaskId: Value(
                          null,
                        ), // Reset parent since moving to new project
                        depth: Value(0), // Reset depth to root level
                      ),
                    );

                    // Update all descendants
                    for (final descendant in allDescendants) {
                      await notifier.updateTask(
                        descendant.id,
                        TaskCompanion(
                          projectId: Value(selectedProject!.id),
                          // Keep existing parent relationships and depths relative to the moved task
                        ),
                      );
                    }
                  }

                  // Invalidate both old and new project providers
                  ref.invalidate(projectTasksNotifier(widget.projectId));
                  ref.invalidate(projectTasksNotifier(selectedProject!.id));

                  navigator.pop(selectedProject);
                }
              : null,
          child: Text('Assign'),
        ),
      ],
    );
  }
}

class AssignTasksToTaskDialog extends ConsumerStatefulWidget {
  final List<TaskData> tasksToAssign;
  final int projectId;
  const AssignTasksToTaskDialog({
    super.key,
    required this.tasksToAssign,
    required this.projectId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AssignTasksToTaskDialogState();
}

class _AssignTasksToTaskDialogState
    extends ConsumerState<AssignTasksToTaskDialog> {
  TaskData? selectedTask;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return AlertDialog(
      title: Text('Assign To A Parent Task'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            SearchTextField<TaskData, TaskSearchNotifier>(
              labelText: "Search Tasks",
              searchProvider: taskSearchProvider,
              getDisplayText: (task) => task.name,
              onItemSelected: (task) => setState(() {
                selectedTask = task;
              }),
              predicates: [
                (task) => task.projectId == widget.projectId,
                // Prevent selecting any of the tasks being moved to avoid circular references
                (task) => !widget.tasksToAssign.any((t) => t.id == task.id),
              ],
            ),
            if (selectedTask != null)
              Card(
                child: ListTile(
                  title: Text('Selected: ${selectedTask!.name}'),
                  trailing: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => setState(() {
                      selectedTask = null;
                    }),
                  ),
                ),
              ),
            Expanded(
              child: Card(
                child: ListView.builder(
                  itemCount: widget.tasksToAssign.length,
                  itemBuilder: (context, index) {
                    final task = widget.tasksToAssign[index];
                    return ListTile(
                      leading: Icon(Icons.task_alt_rounded),
                      title: Text(task.name, overflow: TextOverflow.ellipsis),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: selectedTask != null
              ? () async {
                  final notifier = ref.read(
                    projectTasksNotifier(widget.projectId).notifier,
                  );

                  for (final task in widget.tasksToAssign) {
                    // Get all descendants recursively
                    final allDescendants = await notifier.getAllDescendants(
                      task.id,
                    );

                    // Calculate the depth difference
                    final newParentDepth = selectedTask!.depth;
                    final oldTaskDepth = task.depth;
                    final depthDifference = (newParentDepth + 1) - oldTaskDepth;

                    // Update the main task
                    await notifier.updateTask(
                      task.id,
                      TaskCompanion(
                        parentTaskId: Value(selectedTask!.id),
                        depth: Value(selectedTask!.depth + 1),
                      ),
                    );

                    // Update all descendants with adjusted depths
                    for (final descendant in allDescendants) {
                      await notifier.updateTask(
                        descendant.id,
                        TaskCompanion(
                          depth: Value(descendant.depth + depthDifference),
                        ),
                      );
                    }
                  }

                  ref.invalidate(projectTasksNotifier(widget.projectId));

                  navigator.pop(selectedTask);
                }
              : null,
          child: Text('Assign'),
        ),
      ],
    );
  }
}

Future<ProjectData?> showAssignTasksToProjectDialog(
  BuildContext context,
  List<TaskData> tasks,
  int projectId,
) async {
  return await showDialog<ProjectData>(
    context: context,
    builder: (context) =>
        AssignTasksToProjectDialog(tasksToAssign: tasks, projectId: projectId),
  );
}

Future<TaskData?> showAssignTasksToTaskDialog(
  BuildContext context,
  List<TaskData> tasks,
  int projectId,
) async {
  return await showDialog<TaskData>(
    context: context,
    builder: (context) =>
        AssignTasksToTaskDialog(tasksToAssign: tasks, projectId: projectId),
  );
}
