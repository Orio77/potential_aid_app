import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/stats_provider.dart';
import 'package:time_machine/time_machine.dart';

class Heatmap extends ConsumerWidget {
  final int projectId;
  final String? title;
  static LocalDate fromDate = LocalDate(2025, 09, 01);
  static LocalDate toDate = LocalDate(2025, 09, 30);

  const Heatmap({super.key, this.title, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completions = ref.watch(
      taskCompletionMonthlyNotifier(
        TaskCompletionParams(
          monthYearDate: LocalDate.today(),
          projectId: projectId,
        ),
      ),
    );

    return completions.when(
      data: (data) => _buildHeatMapLayout(context, data),
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text("Error: $error"),
    );
  }

  Widget _buildHeatMapLayout(
    BuildContext context,
    List<TaskCompletionData> completions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(title!, style: Theme.of(context).textTheme.titleMedium),
          ),
        _buildHeatMap(completions),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeatMap(List<TaskCompletionData> completions) {
    final weeks = _getWeeksInRange();
    final completionMap = _buildCompletionMap(completions);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: weeks
                  .map((week) => _buildWeekRow(week, completionMap))
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
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: week.map((date) => _buildDayTile(date, completionMap)).toList(),
    );
  }

  Widget _buildDayTile(LocalDate? date, Map<LocalDate, int> completionMap) {
    final activity = date != null ? (completionMap[date] ?? 0) : 0;
    final color = _getColorForActivity(activity);
    final cellSize = 20.0;

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
              message: '${date.toString()}: $activity activities',
              child: Container(),
            )
          : Container(),
    );
  }

  Color _getColorForActivity(int activity) {
    // GitHub-like green color scheme
    switch (activity) {
      case 0:
        return Colors.grey.shade200;
      case 1:
        return Colors.green.shade100;
      case 2:
        return Colors.green.shade300;
      case 3:
        return Colors.green.shade500;
      case 4:
      default:
        return Colors.green.shade700;
    }
  }

  List<List<LocalDate?>> _getWeeksInRange() {
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

  Map<LocalDate, int> _buildCompletionMap(
    List<TaskCompletionData> completions,
  ) {
    final Map<LocalDate, int> completionMap = {};

    for (final completion in completions) {
      final date = LocalDate(
        completion.completedAt.year,
        completion.completedAt.month,
        completion.completedAt.day,
      );

      // Only include dates within our range
      if (date.compareTo(fromDate) >= 0 && date.compareTo(toDate) <= 0) {
        completionMap[date] = (completionMap[date] ?? 0) + 1;
      }
    }

    return completionMap;
  }
}
