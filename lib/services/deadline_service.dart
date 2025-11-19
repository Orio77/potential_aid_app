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
    final tomorrow = today.addDays(1).toDateTimeUnspecified();

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

      await _updateAllNestedSubtasksDeadline(
        ref: ref,
        parentTaskId: task.id,
        deadline: newDeadline,
        filters: notCompletedFilter,
      );
    }

    // Show confirmation message
    if (context.mounted) {
      _showDeadlineUpdateSnackBar(context, newDeadline);
    }
  }

  static Future<void> _updateAllNestedSubtasksDeadline({
    required WidgetRef ref,
    required int parentTaskId,
    required DateTime deadline,
    required List<Expression<bool> Function($TaskTable)> filters,
  }) async {
    final notifier = ref.read(projectTasksNotifier(parentTaskId).notifier);
    final subtasks = await notifier.getSubtasks(parentTaskId, filters);

    for (final subtask in subtasks) {
      await notifier.updateTask(
        subtask.id,
        TaskCompanion(deadline: Value(deadline)),
      );

      await _updateAllNestedSubtasksDeadline(
        ref: ref,
        parentTaskId: subtask.id,
        deadline: deadline,
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
