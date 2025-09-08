import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/stats_provider.dart';
import 'package:time_machine/time_machine.dart';

class BarMap extends ConsumerWidget {
  final LocalDate monthYearDate;
  const BarMap({super.key, required this.monthYearDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completions = ref.watch(barMapStatsNotifier(monthYearDate));

    return completions.when(
      data: (data) => _buildBarMap(data),
      error: (error, stack) => Text('Error: $error'),
      loading: () => const CircularProgressIndicator(),
    );
  }

  List<double> _formatCompletionData(
    List<TaskCompletionData> completions,
    LocalDate monthYearDate,
  ) {
    final daysInMonth = monthYearDate.calendar.getDaysInMonth(
      monthYearDate.yearOfEra,
      monthYearDate.monthOfYear,
    );

    final dailyCounts = List<double>.filled(daysInMonth, 0.0);

    for (final completion in completions) {
      final dayOfMonth = completion.completedAt.day;
      if (dayOfMonth >= 1 && dayOfMonth <= daysInMonth) {
        dailyCounts[dayOfMonth - 1] += 1;
      }
    }

    return dailyCounts;
  }

  Widget _buildBarMap(List<TaskCompletionData> completions) {
    final completionCounts = _formatCompletionData(completions, monthYearDate);
    final barGroupData = List.generate(completionCounts.length, (i) {
      return BarChartGroupData(
        x: i + 1,
        barRods: [BarChartRodData(toY: completionCounts[i], width: 10)],
      );
    });

    final chartData = BarChartData(barGroups: barGroupData);
    return BarChart(chartData);
  }
}
