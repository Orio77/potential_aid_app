import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/task_completion_provider.dart';
import 'package:potential_aid_app/widgets/enhanced_heatmap_cell.dart';
import 'package:potential_aid_app/widgets/heatmap_widget.dart';

/// Premium heatmap widget with enhanced interactive cells
class PremiumHeatmapWidget extends ConsumerWidget {
  final int projectId;
  final double cellSize;
  final int months;
  final HeatmapOrientation orientation;
  final Function(DateTime date, HeatmapData? data)? onCellTap;

  const PremiumHeatmapWidget({
    Key? key,
    required this.projectId,
    this.cellSize = 12.0,
    this.months = 3,
    this.orientation = HeatmapOrientation.horizontal,
    this.onCellTap,
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

    final heatmapData = ref.watch(heatmapDataStreamProvider(heatmapParams));

    return heatmapData.when(
      data: (data) => _PremiumHeatmapGrid(
        data: data,
        cellSize: cellSize,
        startDate: startDate,
        endDate: endDate,
        orientation: orientation,
        onCellTap: onCellTap,
      ),
      loading: () => SizedBox(
        height: cellSize * 7 + 40,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: cellSize * 7 + 40,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300]),
              const SizedBox(height: 8),
              Text(
                'Error loading data',
                style: TextStyle(color: Colors.red[300]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumHeatmapGrid extends StatelessWidget {
  final List<HeatmapData> data;
  final double cellSize;
  final DateTime startDate;
  final DateTime endDate;
  final HeatmapOrientation orientation;
  final Function(DateTime date, HeatmapData? data)? onCellTap;

  const _PremiumHeatmapGrid({
    required this.data,
    required this.cellSize,
    required this.startDate,
    required this.endDate,
    required this.orientation,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final dataMap = {for (final item in data) item.date: item};
    final maxCompletions = data.isEmpty
        ? 0
        : data.map((e) => e.totalCompletions).reduce((a, b) => a > b ? a : b);

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

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, maxCompletions),
          const SizedBox(height: 12),
          _buildWeekdayLabels(context),
          const SizedBox(height: 4),
          orientation == HeatmapOrientation.horizontal
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: weeks
                      .map(
                        (week) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: week
                              .map(
                                (date) => Padding(
                                  padding: const EdgeInsets.all(1),
                                  child: EnhancedHeatmapCell(
                                    date: date,
                                    dayData: dataMap[date],
                                    maxCompletions: maxCompletions,
                                    cellSize: cellSize,
                                    onTap: () =>
                                        onCellTap?.call(date, dataMap[date]),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: weeks
                      .map(
                        (week) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: week
                              .map(
                                (date) => Padding(
                                  padding: const EdgeInsets.all(1),
                                  child: EnhancedHeatmapCell(
                                    date: date,
                                    dayData: dataMap[date],
                                    maxCompletions: maxCompletions,
                                    cellSize: cellSize,
                                    onTap: () =>
                                        onCellTap?.call(date, dataMap[date]),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                      .toList(),
                ),
          const SizedBox(height: 12),
          _buildLegend(context, maxCompletions),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int maxCompletions) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          'Activity Overview',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const Spacer(),
        if (data.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${data.length} active days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: [
        SizedBox(width: cellSize + 2), // Offset for first column
        ...weekdays.map(
          (day) => Container(
            width: cellSize + 2,
            alignment: Alignment.center,
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, int maxCompletions) {
    return Row(
      children: [
        Text(
          'Less',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final intensity = index / 4.0;
          return Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: index == 0
                  ? Colors.grey[200]!
                  : Color.lerp(
                      Colors.green[100]!,
                      Colors.green[700]!,
                      intensity,
                    )!,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'More',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
        const Spacer(),
        if (maxCompletions > 0)
          Row(
            children: [
              Icon(Icons.trending_up, size: 12, color: Colors.green[600]),
              const SizedBox(width: 4),
              Text(
                'Peak: $maxCompletions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green[600],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
