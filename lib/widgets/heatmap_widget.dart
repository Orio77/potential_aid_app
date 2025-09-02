import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/task_completion_provider.dart';

enum HeatmapOrientation { horizontal, vertical }

class HeatmapWidget extends ConsumerWidget {
  final int year;
  final int? projectId;
  final List<int>? taskIds;
  final double cellSize;
  final double cellSpacing;
  final EdgeInsets padding;
  final HeatmapOrientation orientation;
  final Function(DateTime date, HeatmapData? data)? onCellTap;

  const HeatmapWidget({
    Key? key,
    required this.year,
    this.projectId,
    this.taskIds,
    this.cellSize = 12.0,
    this.cellSpacing = 2.0,
    this.padding = const EdgeInsets.all(16.0),
    this.orientation = HeatmapOrientation.horizontal,
    this.onCellTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapParams = HeatmapParams(
      startDate: DateTime(year, 1, 1),
      endDate: DateTime(year, 12, 31, 23, 59, 59),
      taskIds: taskIds,
      projectId: projectId,
    );

    final heatmapData = ref.watch(heatmapDataProvider(heatmapParams));

    return heatmapData.when(
      data: (data) => _HeatmapGrid(
        year: year,
        data: data,
        cellSize: cellSize,
        cellSpacing: cellSpacing,
        padding: padding,
        onCellTap: onCellTap,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading heatmap: $error')),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final int year;
  final List<HeatmapData> data;
  final double cellSize;
  final double cellSpacing;
  final EdgeInsets padding;
  final Function(DateTime date, HeatmapData? data)? onCellTap;

  const _HeatmapGrid({
    required this.year,
    required this.data,
    required this.cellSize,
    required this.cellSpacing,
    required this.padding,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final dataMap = {for (final item in data) item.date: item};
    final maxCompletions = data.isEmpty
        ? 0
        : data.map((e) => e.totalCompletions).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildHeatmapGrid(context, dataMap, maxCompletions),
            const SizedBox(height: 16),
            _buildLegend(context, maxCompletions),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          year.toString(),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          '${data.length} days active',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildHeatmapGrid(
    BuildContext context,
    Map<DateTime, HeatmapData> dataMap,
    int maxCompletions,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthLabels(context),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeekdayLabels(context),
            const SizedBox(height: 4),
            _buildCalendarGrid(context, dataMap, maxCompletions),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthLabels(BuildContext context) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(height: cellSize + 4), // Offset for weekday labels
        ...List.generate(12, (month) {
          return Container(
            height:
                cellSize * 4 + cellSpacing * 3, // Approximate height for month
            alignment: Alignment.centerRight,
            child: Text(
              months[month],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeekdayLabels(BuildContext context) {
    final weekdays = ['Mon', 'Wed', 'Fri'];

    return SizedBox(
      width: cellSize + cellSpacing,
      child: Column(
        children: weekdays
            .map(
              (day) => Container(
                height: cellSize,
                margin: EdgeInsets.only(bottom: cellSpacing),
                alignment: Alignment.center,
                child: Text(
                  day,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    Map<DateTime, HeatmapData> dataMap,
    int maxCompletions,
  ) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);
    final startDate = startOfYear.subtract(
      Duration(days: startOfYear.weekday - 1),
    );

    final weeks = <List<DateTime>>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endOfYear) ||
        currentDate.isAtSameMomentAs(endOfYear)) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return Row(
      children: weeks
          .map(
            (week) => _buildWeekColumn(context, week, dataMap, maxCompletions),
          )
          .toList(),
    );
  }

  Widget _buildWeekColumn(
    BuildContext context,
    List<DateTime> week,
    Map<DateTime, HeatmapData> dataMap,
    int maxCompletions,
  ) {
    return Container(
      margin: EdgeInsets.only(right: cellSpacing),
      child: Column(
        children: week
            .map(
              (date) =>
                  _buildDayCell(context, date, dataMap[date], maxCompletions),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    HeatmapData? dayData,
    int maxCompletions,
  ) {
    final isCurrentYear = date.year == year;
    final completions = dayData?.totalCompletions ?? 0;
    final intensity = maxCompletions > 0 ? (completions / maxCompletions) : 0.0;

    Color cellColor;
    if (!isCurrentYear) {
      cellColor = Colors.grey[100]!;
    } else if (completions == 0) {
      cellColor = Colors.grey[200]!;
    } else {
      cellColor = Color.lerp(
        Colors.green[100]!,
        Colors.green[700]!,
        intensity,
      )!;
    }

    final tooltipMessage = _buildTooltipMessage(date, dayData);

    return Tooltip(
      message: tooltipMessage,
      decoration: BoxDecoration(
        color: Colors.grey[800]!,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {},
        onExit: (_) {},
        child: GestureDetector(
          onTap: () => onCellTap?.call(date, dayData),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: cellSize,
            height: cellSize,
            margin: EdgeInsets.only(bottom: cellSpacing),
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(2),
              border: completions > 0
                  ? Border.all(color: Colors.green[800]!, width: 0.5)
                  : Border.all(color: Colors.transparent, width: 0.5),
              boxShadow: completions > 0
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: completions > 0 && cellSize > 16
                ? Center(
                    child: Text(
                      completions.toString(),
                      style: TextStyle(
                        fontSize: cellSize * 0.6,
                        fontWeight: FontWeight.bold,
                        color: intensity > 0.5 ? Colors.white : Colors.black,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  String _buildTooltipMessage(DateTime date, HeatmapData? dayData) {
    final dayName = _getDayName(date.weekday);
    final monthName = _getMonthName(date.month);
    final dateStr = '$dayName, $monthName ${date.day}, ${date.year}';

    if (dayData == null || dayData.totalCompletions == 0) {
      return '$dateStr\nNo tasks completed';
    }

    final completions = dayData.totalCompletions;
    final taskCount = dayData.taskBreakdown.length;

    String message = '$dateStr\n$completions task completion';
    if (completions != 1) message += 's';

    if (taskCount > 1) {
      message += ' across $taskCount tasks';
    }

    // Add task breakdown for detailed view
    if (dayData.taskBreakdown.isNotEmpty && taskCount <= 3) {
      message += '\n\nBreakdown:';
      dayData.taskBreakdown.forEach((taskId, count) {
        message += '\nTask $taskId: $count completion';
        if (count != 1) message += 's';
      });
    }

    return message;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildLegend(BuildContext context, int maxCompletions) {
    return Row(
      children: [
        Text(
          'Less',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final intensity = index / 4.0;
          return Container(
            width: cellSize,
            height: cellSize,
            margin: EdgeInsets.only(right: cellSpacing),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const Spacer(),
        if (maxCompletions > 0)
          Text(
            'Max: $maxCompletions',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
      ],
    );
  }
}

// Constrained heatmap that works in limited width contexts
class ConstrainedHeatmapWidget extends ConsumerWidget {
  final int year;
  final int? projectId;
  final List<int>? taskIds;
  final double cellSize;
  final double cellSpacing;
  final double maxWidth;
  final HeatmapOrientation orientation;
  final Function(DateTime date, HeatmapData? data)? onCellTap;

  const ConstrainedHeatmapWidget({
    Key? key,
    required this.year,
    this.projectId,
    this.taskIds,
    this.cellSize = 8.0,
    this.cellSpacing = 1.0,
    this.maxWidth = 300.0,
    this.orientation = HeatmapOrientation.horizontal,
    this.onCellTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmapParams = HeatmapParams(
      startDate: DateTime(year, 1, 1),
      endDate: DateTime(year, 12, 31, 23, 59, 59),
      taskIds: taskIds,
      projectId: projectId,
    );

    final heatmapData = ref.watch(heatmapDataProvider(heatmapParams));

    return heatmapData.when(
      data: (data) => _ConstrainedHeatmapGrid(
        year: year,
        data: data,
        cellSize: cellSize,
        cellSpacing: cellSpacing,
        maxWidth: maxWidth,
        onCellTap: onCellTap,
      ),
      loading: () => SizedBox(
        height: cellSize * 7 + cellSpacing * 6 + 40,
        width: maxWidth,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: cellSize * 7 + cellSpacing * 6 + 40,
        width: maxWidth,
        child: const Center(child: Icon(Icons.error)),
      ),
    );
  }
}

class _ConstrainedHeatmapGrid extends StatelessWidget {
  final int year;
  final List<HeatmapData> data;
  final double cellSize;
  final double cellSpacing;
  final double maxWidth;
  final Function(DateTime date, HeatmapData? data)? onCellTap;

  const _ConstrainedHeatmapGrid({
    required this.year,
    required this.data,
    required this.cellSize,
    required this.cellSpacing,
    required this.maxWidth,
    this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final dataMap = {for (final item in data) item.date: item};
    final maxCompletions = data.isEmpty
        ? 0
        : data.map((e) => e.totalCompletions).reduce((a, b) => a > b ? a : b);

    return Container(
      width: maxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          Container(
            height: cellSize * 7 + cellSpacing * 6,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildCalendarGrid(context, dataMap, maxCompletions),
            ),
          ),
          const SizedBox(height: 8),
          _buildLegend(context, maxCompletions),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          year.toString(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          '${data.length} days',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    Map<DateTime, HeatmapData> dataMap,
    int maxCompletions,
  ) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);
    final startDate = startOfYear.subtract(
      Duration(days: startOfYear.weekday - 1),
    );

    final weeks = <List<DateTime>>[];
    var currentDate = startDate;

    while (currentDate.isBefore(endOfYear) ||
        currentDate.isAtSameMomentAs(endOfYear)) {
      final week = <DateTime>[];
      for (int i = 0; i < 7; i++) {
        week.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return Row(
      children: weeks
          .map(
            (week) => _buildWeekColumn(context, week, dataMap, maxCompletions),
          )
          .toList(),
    );
  }

  Widget _buildWeekColumn(
    BuildContext context,
    List<DateTime> week,
    Map<DateTime, HeatmapData> dataMap,
    int maxCompletions,
  ) {
    return Container(
      margin: EdgeInsets.only(right: cellSpacing),
      child: Column(
        children: week
            .map(
              (date) =>
                  _buildDayCell(context, date, dataMap[date], maxCompletions),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    HeatmapData? dayData,
    int maxCompletions,
  ) {
    final isCurrentYear = date.year == year;
    final completions = dayData?.totalCompletions ?? 0;
    final intensity = maxCompletions > 0 ? (completions / maxCompletions) : 0.0;

    Color cellColor;
    if (!isCurrentYear) {
      cellColor = Colors.grey[100]!;
    } else if (completions == 0) {
      cellColor = Colors.grey[200]!;
    } else {
      cellColor = Color.lerp(
        Colors.green[100]!,
        Colors.green[700]!,
        intensity,
      )!;
    }

    final tooltipMessage = _buildTooltipMessage(date, dayData);

    return Tooltip(
      message: tooltipMessage,
      decoration: BoxDecoration(
        color: Colors.grey[800]!,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onCellTap?.call(date, dayData),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: cellSize,
            height: cellSize,
            margin: EdgeInsets.only(bottom: cellSpacing),
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(1),
              border: completions > 0
                  ? Border.all(color: Colors.green[800]!, width: 0.3)
                  : null,
              boxShadow: completions > 0
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 1,
                        offset: const Offset(0, 0.5),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  String _buildTooltipMessage(DateTime date, HeatmapData? dayData) {
    final dayName = _getDayName(date.weekday);
    final monthName = _getMonthName(date.month);
    final dateStr = '$dayName, $monthName ${date.day}, ${date.year}';

    if (dayData == null || dayData.totalCompletions == 0) {
      return '$dateStr\nNo tasks completed';
    }

    final completions = dayData.totalCompletions;
    final taskCount = dayData.taskBreakdown.length;

    String message = '$dateStr\n$completions task completion';
    if (completions != 1) message += 's';

    if (taskCount > 1) {
      message += ' across $taskCount tasks';
    }

    return message;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
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
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          final intensity = index / 4.0;
          return Container(
            width: cellSize * 0.8,
            height: cellSize * 0.8,
            margin: EdgeInsets.only(right: cellSpacing),
            decoration: BoxDecoration(
              color: index == 0
                  ? Colors.grey[200]!
                  : Color.lerp(
                      Colors.green[100]!,
                      Colors.green[700]!,
                      intensity,
                    )!,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
        const SizedBox(width: 4),
        Text(
          'More',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
        const Spacer(),
        if (maxCompletions > 0)
          Text(
            '$maxCompletions',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}

// Compact heatmap for project info widget
class CompactHeatmapWidget extends ConsumerWidget {
  final int projectId;
  final double cellSize;
  final int months; // Number of months to show
  final HeatmapOrientation orientation;

  const CompactHeatmapWidget({
    Key? key,
    required this.projectId,
    this.cellSize = 8.0,
    this.months = 3,
    this.orientation = HeatmapOrientation.horizontal,
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
      data: (data) => Container(
        constraints: BoxConstraints(
          maxHeight: orientation == HeatmapOrientation.horizontal
              ? cellSize * 7 +
                    14 // 7 days + margins
              : double.infinity,
          maxWidth: orientation == HeatmapOrientation.vertical
              ? cellSize * 7 +
                    14 // 7 days + margins
              : double.infinity,
        ),
        child: _CompactHeatmapGrid(
          data: data,
          cellSize: cellSize,
          startDate: startDate,
          endDate: endDate,
          orientation: orientation,
        ),
      ),
      loading: () => SizedBox(
        height: cellSize * 7 + 14,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: cellSize * 7 + 14,
        child: const Center(child: Icon(Icons.error)),
      ),
    );
  }
}

class _CompactHeatmapGrid extends StatelessWidget {
  final List<HeatmapData> data;
  final double cellSize;
  final DateTime startDate;
  final DateTime endDate;
  final HeatmapOrientation orientation;

  const _CompactHeatmapGrid({
    required this.data,
    required this.cellSize,
    required this.startDate,
    required this.endDate,
    required this.orientation,
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

    return orientation == HeatmapOrientation.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: weeks
                .map(
                  (week) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: week
                        .map(
                          (date) => _buildCompactCell(
                            context,
                            date,
                            dataMap[date],
                            maxCompletions,
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
                          (date) => _buildCompactCell(
                            context,
                            date,
                            dataMap[date],
                            maxCompletions,
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          );
  }

  Widget _buildCompactCell(
    BuildContext context,
    DateTime date,
    HeatmapData? dayData,
    int maxCompletions,
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

    final tooltipMessage = _buildCompactTooltipMessage(date, dayData);

    return Tooltip(
      message: tooltipMessage,
      decoration: BoxDecoration(
        color: Colors.grey[800]!,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      child: MouseRegion(
        cursor: completions > 0
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: cellSize,
          height: cellSize,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(1),
            boxShadow: completions > 0
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 1,
                      offset: const Offset(0, 0.5),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  String _buildCompactTooltipMessage(DateTime date, HeatmapData? dayData) {
    final dayName = _getDayName(date.weekday);
    final monthName = _getMonthName(date.month);
    final dateStr = '$dayName, $monthName ${date.day}';

    if (dayData == null || dayData.totalCompletions == 0) {
      return '$dateStr\nNo completions';
    }

    final completions = dayData.totalCompletions;
    return '$dateStr\n$completions completion${completions != 1 ? 's' : ''}';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

// Adaptive heatmap that chooses the right layout based on available space
class AdaptiveHeatmapWidget extends StatelessWidget {
  final int year;
  final int? projectId;
  final List<int>? taskIds;
  final HeatmapOrientation orientation;
  final Function(DateTime date, HeatmapData? data)? onCellTap;

  const AdaptiveHeatmapWidget({
    Key? key,
    required this.year,
    this.projectId,
    this.taskIds,
    this.orientation = HeatmapOrientation.horizontal,
    this.onCellTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If we have plenty of width, use the full heatmap
        if (constraints.maxWidth > 600) {
          return HeatmapWidget(
            year: year,
            projectId: projectId,
            taskIds: taskIds,
            orientation: orientation,
            onCellTap: onCellTap,
          );
        }
        // Otherwise use the constrained version
        else {
          return ConstrainedHeatmapWidget(
            year: year,
            projectId: projectId,
            taskIds: taskIds,
            maxWidth: constraints.maxWidth - 32, // Account for padding
            orientation: orientation,
            onCellTap: onCellTap,
          );
        }
      },
    );
  }
}
