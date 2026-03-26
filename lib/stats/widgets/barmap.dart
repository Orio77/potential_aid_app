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
      blockCompletionMonthlyNotifier(monthYearDate),
    );

    return completions.when(
      data: (data) => _buildBarMap(data),
      error: (error, stack) => Text('Error: $error'),
      loading: () => const CircularProgressIndicator(),
    );
  }

  Widget _buildBarMap(List<BlockCompletionData> completions) {
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
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final day = value.toInt();
                  // Show every other day (odd days only)
                  if (day % 2 == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        day.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 25,
                interval: maxCount > 10 ? (maxCount / 5).ceilToDouble() : null,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxCount > 10
                ? (maxCount / 5).ceilToDouble()
                : null,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.5),
                strokeWidth: 0.5,
              );
            },
          ),
          borderData: FlBorderData(show: false),
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
          final hours = completionCount ~/ 60;
          final minutes = completionCount % 60;
          final tooltipText =
              'Day $dayNumber\n${hours > 0 ? '$hours ${hours == 1 ? "hour" : "hours"} ' : ''}$minutes ${minutes == 1 ? "minute" : "minutes"}';

          return BarTooltipItem(
            tooltipText,
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          );
        },
      ),
    );
  }
}
