import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/breakdown/constants/task_breakdown_constants.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/breakdown/models/subtask_item.dart';
import 'package:potential_aid_app/breakdown/screens/task_breakdown_screen.dart';
import 'package:potential_aid_app/services/deadline_service.dart';
import 'package:potential_aid_app/projects/widgets/complete_task_dialog.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';

/// Complete task button for subtasks
class CompleteTaskButton extends ConsumerWidget {
  final SubtaskItem subtask;
  final TaskData parentTask;
  final VoidCallback onComplete;

  const CompleteTaskButton({
    super.key,
    required this.subtask,
    required this.parentTask,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!subtask.isExisting ||
        subtask.taskData == null ||
        subtask.taskData!.isCompleted) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () async {
        final task = await ref
            .read(projectTasksNotifier(parentTask.projectId).notifier)
            .getTask(subtask.savedId);
        if (context.mounted) {
          await showCompleteTaskDialog(context, task);
          onComplete();
        }
      },
      icon: const Icon(Icons.task_alt_sharp),
    );
  }
}

/// Button to change deadline for tomorrow
class ChangeDeadlineForTomorrowButton extends ConsumerWidget {
  final SubtaskItem subtask;

  const ChangeDeadlineForTomorrowButton({
    super.key,
    required this.subtask,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!subtask.isExisting) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () async => await DeadlineService.moveTaskToTomorrow(
        ref: ref,
        context: context,
        task: subtask.taskData!,
      ),
      icon: const Icon(Icons.edit_calendar_rounded),
    );
  }
}

/// Toggle search mode button
class ToggleSearchButton extends StatelessWidget {
  final SubtaskItem subtask;
  final VoidCallback onToggle;

  const ToggleSearchButton({
    super.key,
    required this.subtask,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (subtask.isExisting) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: onToggle,
      icon: const Icon(Icons.search),
    );
  }
}

/// Remove subtask button
class RemoveSubtaskButton extends StatelessWidget {
  final VoidCallback onRemove;

  const RemoveSubtaskButton({
    super.key,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onRemove,
      icon: const Icon(Icons.delete),
    );
  }
}

/// Breakdown subtask button (navigate to subtask breakdown)
class BreakdownSubtaskButton extends ConsumerWidget {
  final SubtaskItem subtask;
  final TaskData parentTask;
  final VoidCallback onSaveNeeded;

  const BreakdownSubtaskButton({
    super.key,
    required this.subtask,
    required this.parentTask,
    required this.onSaveNeeded,
  });

  /// Helper method to check if a subtask is new (not yet saved)
  bool get _isNewSubtask => subtask.savedId == TaskBreakdownConstants.newSubtaskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _navigateToBreakdown(context, ref),
      icon: const Icon(Icons.account_tree_rounded),
    );
  }

  Future<void> _navigateToBreakdown(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final navigator = Navigator.of(context);

    if (!_isNewSubtask) {
      final task = await ref
          .read(projectTasksNotifier(parentTask.projectId).notifier)
          .getTask(subtask.savedId);
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => TaskBreakdownScreen(task: task),
        ),
      );
    } else {
      // Need to save first
      onSaveNeeded();
    }
  }
}

/// Go to parent task button
class GoToParentTaskButton extends ConsumerWidget {
  final TaskData task;

  const GoToParentTaskButton({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _navigateToParent(context, ref),
      icon: const Icon(Icons.arrow_circle_left_outlined),
    );
  }

  Future<void> _navigateToParent(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final parentTask = await ref
        .read(projectTasksNotifier(task.projectId).notifier)
        .getTask(task.parentTaskId!);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (context) => TaskBreakdownScreen(task: parentTask),
      ),
    );
  }
}

/// Subtask count indicator
class SubtaskCountInfo extends StatelessWidget {
  final int count;

  const SubtaskCountInfo({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 0, 0, 0),
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
}
