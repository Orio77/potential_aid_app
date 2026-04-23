import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';

class DeadlineService {
  static Future<void> moveTaskToTomorrow({
    required WidgetRef ref,
    required BuildContext context,
    required TaskData task,
    bool updateNestedSubtasks = true,
  }) async {
    final today = ref.read(dateNotifierProvider.notifier).getTodaysDate();
    DateTime tomorrow = today.addDays(1).toDateTimeUnspecified();

    // Cap at parent's deadline when this is a subtask.
    if (task.parentTaskId != null) {
      final parent = await ref
          .read(projectTasksNotifier(task.projectId).notifier)
          .getParent(task.id);
      if (parent?.deadline != null && tomorrow.isAfter(parent!.deadline!)) {
        tomorrow = parent.deadline!;
      }
    }

    if (!context.mounted) return;

    await updateTaskDeadline(
      ref: ref,
      context: context,
      task: task,
      newDeadline: tomorrow,
      updateNestedSubtasks: updateNestedSubtasks,
    );
  }

  static Future<void> updateTaskDeadline({
    required WidgetRef ref,
    required BuildContext context,
    required TaskData task,
    required DateTime newDeadline,
    bool updateNestedSubtasks = true,
  }) async {
    final notifier = ref.read(projectTasksNotifier(task.projectId).notifier);

    final oldDeadline = task.deadline;

    // Update the main task
    await notifier.updateTask(
      task.id,
      TaskCompanion(deadline: Value(newDeadline)),
    );

    // Update nested subtasks if requested
    if (updateNestedSubtasks) {
      final notCompletedFilter = <Expression<bool> Function($TaskTable)>[
        (table) => table.isCompleted.equals(false),
      ];

      final dayShift = oldDeadline == null
          ? 0
          : DateUtils.dateOnly(
              newDeadline,
            ).difference(DateUtils.dateOnly(oldDeadline)).inDays;

      await _updateAllNestedSubtasksDeadline(
        ref: ref,
        projectId: task.projectId,
        parentTaskId: task.id,
        dayShift: dayShift,
        fallbackDeadline: newDeadline,
        filters: notCompletedFilter,
      );

      await notifier.refresh();
    }

    // Show confirmation message
    if (context.mounted) {
      _showDeadlineUpdateSnackBar(context, newDeadline);
    }
  }

  static Future<void> _updateAllNestedSubtasksDeadline({
    required WidgetRef ref,
    required int projectId,
    required int parentTaskId,
    required int dayShift,
    required DateTime fallbackDeadline,
    required List<Expression<bool> Function($TaskTable)> filters,
  }) async {
    final notifier = ref.read(projectTasksNotifier(projectId).notifier);
    final subtasks = await notifier.getSubtasks(parentTaskId, filters);

    for (final subtask in subtasks) {
      final shiftedDeadline = subtask.deadline == null
          ? fallbackDeadline
          : subtask.deadline!.add(Duration(days: dayShift));

      await notifier.updateTaskSilent(
        subtask.id,
        TaskCompanion(deadline: Value(shiftedDeadline)),
      );

      await _updateAllNestedSubtasksDeadline(
        ref: ref,
        projectId: projectId,
        parentTaskId: subtask.id,
        dayShift: dayShift,
        fallbackDeadline: fallbackDeadline,
        filters: filters,
      );
    }
  }

  static void _showDeadlineUpdateSnackBar(
    BuildContext context,
    DateTime deadline,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            "Moved task to: ${deadline.day}-${deadline.month}-${deadline.year}",
            style: const TextStyle(fontSize: 20),
          ),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }
}
