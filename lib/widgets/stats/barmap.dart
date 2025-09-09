import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/stats_provider.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';
import 'package:time_machine/time_machine.dart';

class BarMap extends ConsumerWidget {
  final LocalDate monthYearDate;
  const BarMap({super.key, required this.monthYearDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completions = ref.watch(
      taskCompletionMonthlyNotifier(
        TaskCompletionParams(monthYearDate: monthYearDate),
      ),
    );

    return completions.when(
      data: (data) => _buildBarMap(data),
      error: (error, stack) => Text('Error: $error'),
      loading: () => const CircularProgressIndicator(),
    );
  }

  Widget _buildBarMap(List<TaskCompletionData> completions) {
    final completionCounts = CompletionUtils.formatCompletionData(
      completions,
      monthYearDate,
    );

    return Builder(
      builder: (context) {
        final maxCount = completionCounts.isEmpty
            ? 1.0
            : completionCounts.reduce((a, b) => a > b ? a : b);

        final barGroupData = List.generate(completionCounts.length, (i) {
          final percentage = maxCount > 0
              ? (completionCounts[i] / maxCount) * 100
              : 0.0;
          final color = CompletionUtils.getCompletionColor(percentage);

          return BarChartGroupData(
            x: i + 1,
            barRods: [
              BarChartRodData(
                toY: completionCounts[i],
                width: 10,
                color: color,
              ),
            ],
          );
        });

        final chartData = BarChartData(
          barGroups: barGroupData,
          barTouchData: _getBarTouchData(),
        );
        return BarChart(chartData);
      },
    );
  }

  BarTouchData _getBarTouchData() {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final dayNumber = group.x;
          final completionCount = rod.toY.toInt();

          return BarTooltipItem(
            'Day $dayNumber\n$completionCount completions',
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          );
        },
      ),
    );
  }
}
