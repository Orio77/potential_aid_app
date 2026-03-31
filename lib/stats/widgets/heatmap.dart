import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/stats/providers/stats_provider.dart';
import 'package:time_machine/time_machine.dart';

class Heatmap extends ConsumerWidget {
  final int projectId;
  final String? title;

  const Heatmap({super.key, this.title, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [C] Use completed tasks (isCompleted=true + completedAt) instead of raw
    // task_completion events, so each day reflects tasks actually finished.
    final completions = ref.watch(
      completedTasksByMonthProvider(
        TaskCompletionParams(
          monthYearDate: LocalDate.today(),
          projectId: projectId,
        ),
      ),
    );

    final today = ref.watch(dateNotifierProvider);
    final startOfMonth = LocalDate(today.yearOfEra, today.monthOfYear, 1);
    final endOfMonth = startOfMonth.addMonths(1).subtractDays(1);

    return completions.when(
      data: (data) =>
          _buildHeatMapLayout(context, data, startOfMonth, endOfMonth),
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text("Error: $error"),
    );
  }

  Widget _buildHeatMapLayout(
    BuildContext context,
    List<TaskData> completions,
    LocalDate startOfMonth,
    LocalDate endOfMonth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(title!, style: Theme.of(context).textTheme.titleMedium),
          ),
        _buildHeatMap(completions, startOfMonth, endOfMonth),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeatMap(
    List<TaskData> completions,
    LocalDate fromDate,
    LocalDate toDate,
  ) {
    final weeks = _getWeeksInRange(fromDate, toDate);
    final completionMap = _buildCompletionMap(completions, fromDate, toDate);

    // [D] Scale colour relative to the busiest day in the month (like GitHub).
    final maxActivity = completionMap.values.isEmpty
        ? 1
        : completionMap.values.reduce(max);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: weeks
                  .map((week) => _buildWeekRow(week, completionMap, maxActivity))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekRow(
    List<LocalDate?> week,
    Map<LocalDate, int> completionMap,
    int maxActivity,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: week
          .map((date) => _buildDayTile(date, completionMap, maxActivity))
          .toList(),
    );
  }

  Widget _buildDayTile(
    LocalDate? date,
    Map<LocalDate, int> completionMap,
    int maxActivity,
  ) {
    final count = date != null ? (completionMap[date] ?? 0) : 0;
    final color = _getColorForActivity(count, maxActivity);
    const cellSize = 20.0;

    return Container(
      margin: const EdgeInsets.all(1.0),
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: date != null ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
        border: date != null
            ? Border.all(color: Colors.grey.shade300, width: 0.5)
            : null,
      ),
      child: date != null
          ? Tooltip(
              enableTapToDismiss: true,
              triggerMode: TooltipTriggerMode.tap,
              message: '${date.toString()}: $count ${count == 1 ? "task" : "tasks"} completed',
              child: Container(),
            )
          : Container(),
    );
  }

  /// [D] Maps a raw count to a colour level scaled against the month's max.
  Color _getColorForActivity(int count, int maxActivity) {
    if (count == 0 || maxActivity == 0) return Colors.grey.shade200;
    // Scale 1..maxActivity → level 1..4
    final level = ((count / maxActivity) * 4).ceil().clamp(1, 4);
    switch (level) {
      case 1:
        return Colors.deepPurpleAccent.shade100;
      case 2:
        return Colors.deepPurpleAccent.shade200;
      case 3:
        return Colors.deepPurpleAccent.shade400;
      case 4:
      default:
        return Colors.deepPurpleAccent.shade700;
    }
  }

  List<List<LocalDate?>> _getWeeksInRange(
    LocalDate fromDate,
    LocalDate toDate,
  ) {
    final weeks = <List<LocalDate?>>[];
    var currentDate = fromDate;

    var startOfWeek = currentDate;
    while (startOfWeek.dayOfWeek != DayOfWeek.monday) {
      startOfWeek = startOfWeek.addDays(-1);
    }

    while (startOfWeek.compareTo(toDate) <= 0) {
      final week = <LocalDate?>[];

      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.addDays(i);
        if (date.compareTo(fromDate) >= 0 && date.compareTo(toDate) <= 0) {
          week.add(date);
        } else {
          week.add(null);
        }
      }

      weeks.add(week);
      startOfWeek = startOfWeek.addDays(7);
    }

    return weeks;
  }

  /// [C] Build a per-day map from completed tasks using their completedAt field.
  Map<LocalDate, int> _buildCompletionMap(
    List<TaskData> completions,
    LocalDate fromDate,
    LocalDate toDate,
  ) {
    final Map<LocalDate, int> completionMap = {};

    for (final task in completions) {
      if (task.completedAt == null) continue;
      final dt = task.completedAt!;
      final date = LocalDate(dt.year, dt.month, dt.day);

      if (date.compareTo(fromDate) >= 0 && date.compareTo(toDate) <= 0) {
        completionMap[date] = (completionMap[date] ?? 0) + 1;
      }
    }

    return completionMap;
  }
}
