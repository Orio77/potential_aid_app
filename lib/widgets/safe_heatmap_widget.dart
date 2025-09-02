import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/task_completion_provider.dart';

/// A completely overflow-safe heatmap widget for project info cards
class SafeHeatmapWidget extends ConsumerWidget {
  final int projectId;
  final double cellSize;
  final int months;
  final double maxHeight;

  const SafeHeatmapWidget({
    Key? key,
    required this.projectId,
    this.cellSize = 6.0,
    this.months = 3,
    this.maxHeight = 60.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);
    final endDate = DateTime(
      now.year,
      now.month,
      DateTime(now.year, now.month + 1, 0).day,
    );

    final heatmapParams = HeatmapParams(
      startDate: startDate,
      endDate: endDate,
      projectId: projectId,
    );

    final heatmapData = ref.watch(heatmapDataProvider(heatmapParams));

    return Container(
      height: maxHeight,
      child: heatmapData.when(
        data: (data) => _SafeHeatmapGrid(
          data: data,
          cellSize: cellSize,
          startDate: startDate,
          endDate: endDate,
          maxHeight: maxHeight,
        ),
        loading: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (error, stack) =>
            const Center(child: Icon(Icons.error, size: 20)),
      ),
    );
  }
}

class _SafeHeatmapGrid extends StatelessWidget {
  final List<HeatmapData> data;
  final double cellSize;
  final DateTime startDate;
  final DateTime endDate;
  final double maxHeight;

  const _SafeHeatmapGrid({
    required this.data,
    required this.cellSize,
    required this.startDate,
    required this.endDate,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final dataMap = {for (final item in data) item.date: item};
    final maxCompletions = data.isEmpty
        ? 0
        : data.map((e) => e.totalCompletions).reduce((a, b) => a > b ? a : b);

    // Calculate optimal cell size to fit in available height
    final availableHeight = maxHeight - 20; // Leave space for label
    final optimalCellSize = (availableHeight / 7).clamp(2.0, cellSize);

    final weeks = <List<DateTime>>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        if (currentDate.isAfter(endDate)) break;
        week.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simple label
        Text(
          'Activity (${data.length} days)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        // Scrollable heatmap that fits remaining space
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: weeks
                  .map(
                    (week) => Padding(
                      padding: const EdgeInsets.only(right: 1),
                      child: Column(
                        children: week
                            .map(
                              (date) => _buildSafeCell(
                                context,
                                date,
                                dataMap[date],
                                maxCompletions,
                                optimalCellSize,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSafeCell(
    BuildContext context,
    DateTime date,
    HeatmapData? dayData,
    int maxCompletions,
    double actualCellSize,
  ) {
    final completions = dayData?.totalCompletions ?? 0;
    final intensity = maxCompletions > 0 ? (completions / maxCompletions) : 0.0;

    Color cellColor;
    if (completions == 0) {
      cellColor = Colors.grey[200]!;
    } else {
      cellColor = Color.lerp(
        Colors.green[100]!,
        Colors.green[700]!,
        intensity,
      )!;
    }

    return Container(
      width: actualCellSize,
      height: actualCellSize,
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
