import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/providers/timeline_date_notifier.dart';
import 'package:potential_aid_app/widgets/timeline/task_card.dart';
import 'package:time_machine/time_machine.dart';

class TaskCards extends ConsumerStatefulWidget {
  final int? depth;
  final double dayCardWidth;
  final LocalDate timelineStart;

  const TaskCards({
    super.key,
    required this.timelineStart,
    required this.dayCardWidth,
    this.depth,
  });

  @override
  ConsumerState<TaskCards> createState() => _TaskCardsState();
}

class _TaskCardsState extends ConsumerState<TaskCards> {
  late int depth;

  @override
  void initState() {
    super.initState();
    depth = widget.depth ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(timelineDateNotifierProvider);
    final tasksByDate = ref.watch(taskCardsNotifierProvider);

    ref.listen(timelineDateNotifierProvider, (previous, next) {
      if (previous != next) {
        ref
            .read(taskCardsNotifierProvider.notifier)
            .loadTasksForMonth(next, depth: depth);
      }
    });

    if (tasksByDate.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(taskCardsNotifierProvider.notifier)
            .loadTasksForMonth(currentMonth, depth: depth);
      });
    }

    return _buildTaskGrid(tasksByDate);
  }

  Widget _buildTaskGrid(Map<LocalDate, List<TaskData>> tasksByDate) {
    final datesInMonth = ref
        .read(timelineDateNotifierProvider.notifier)
        .getAllDaysInMonth();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: datesInMonth.map((date) {
        final tasksForDay = tasksByDate[date] ?? [];
        return _buildDayColumn(date, tasksForDay);
      }).toList(),
    );
  }

  Widget _buildDayColumn(LocalDate date, List<TaskData> tasks) {
    return SizedBox(
      width: widget.dayCardWidth,
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...tasks.map(
            (task) => TaskCard(task: task, width: widget.dayCardWidth - 16),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
