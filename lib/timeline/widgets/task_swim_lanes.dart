import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/breakdown/screens/task_breakdown_screen.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/timeline/providers/task_cards_notifier.dart';
import 'package:time_machine/time_machine.dart';

/// Horizontal swim-lane view: one row per project, tasks positioned at their
/// deadline date. Replaces the vertical column view on desktop when toggled.
class TaskSwimLanes extends ConsumerWidget {
  final int depth;
  final double dayCardWidth;
  final LocalDate timelineStart;
  final List<LocalDate> datesInRange;

  const TaskSwimLanes({
    super.key,
    required this.depth,
    required this.dayCardWidth,
    required this.timelineStart,
    required this.datesInRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksByDate = ref.watch(taskCardsNotifierProvider(depth));

    // Invert: group tasks by projectId
    final tasksByProject = <int, List<TaskData>>{};
    for (final tasks in tasksByDate.values) {
      for (final task in tasks) {
        tasksByProject.putIfAbsent(task.projectId, () => []).add(task);
      }
    }

    if (tasksByProject.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(child: Text('No tasks this period')),
      );
    }

    final sortedIds = tasksByProject.keys.toList()
      ..sort(
        (a, b) => tasksByProject[b]!.length.compareTo(tasksByProject[a]!.length),
      );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...sortedIds.map(
          (pid) => _SwimLaneRow(
            projectId: pid,
            tasks: tasksByProject[pid]!,
            dayCardWidth: dayCardWidth,
            datesInRange: datesInRange,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SwimLaneRow extends ConsumerWidget {
  final int projectId;
  final List<TaskData> tasks;
  final double dayCardWidth;
  final List<LocalDate> datesInRange;

  static const double _rowHeight = 52.0;

  const _SwimLaneRow({
    required this.projectId,
    required this.tasks,
    required this.dayCardWidth,
    required this.datesInRange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(projectId));
    final projectName = projectAsync.valueOrNull?.name ?? '…';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Project label row
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2, left: 8),
          child: Text(
            projectName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        // Lane: tasks positioned at their deadline column
        SizedBox(
          height: _rowHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Lane background
              Container(
                height: _rowHeight,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              // Task chips at deadline positions
              ...tasks.map((task) {
                if (task.deadline == null) return const SizedBox.shrink();
                final deadline = LocalDate.dateTime(task.deadline!);
                final idx = datesInRange.indexWhere((d) => d == deadline);
                if (idx < 0) return const SizedBox.shrink();

                return Positioned(
                  left: idx * dayCardWidth + 2,
                  top: 4,
                  width: dayCardWidth - 4,
                  height: _rowHeight - 8,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaskBreakdownScreen(task: task),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? Colors.green.shade100
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: task.isCompleted
                              ? Colors.green.shade400
                              : Colors.blue.shade400,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 11,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? Colors.green.shade700
                              : Colors.blue.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
