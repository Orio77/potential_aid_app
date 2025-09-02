import 'package:flutter/material.dart';
import 'package:potential_aid_app/providers/task_completion_provider.dart';

/// An enhanced heatmap cell with advanced hover effects and information display
class EnhancedHeatmapCell extends StatefulWidget {
  final DateTime date;
  final HeatmapData? dayData;
  final int maxCompletions;
  final double cellSize;
  final VoidCallback? onTap;
  final Color baseColor;
  final Color highlightColor;

  const EnhancedHeatmapCell({
    Key? key,
    required this.date,
    required this.dayData,
    required this.maxCompletions,
    required this.cellSize,
    this.onTap,
    this.baseColor = Colors.grey,
    this.highlightColor = Colors.green,
  }) : super(key: key);

  @override
  State<EnhancedHeatmapCell> createState() => _EnhancedHeatmapCellState();
}

class _EnhancedHeatmapCellState extends State<EnhancedHeatmapCell>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completions = widget.dayData?.totalCompletions ?? 0;
    final intensity = widget.maxCompletions > 0
        ? (completions / widget.maxCompletions)
        : 0.0;

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

    final tooltipMessage = _buildDetailedTooltip();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Tooltip(
            message: tooltipMessage,
            decoration: BoxDecoration(
              color: Colors.grey[900]!,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.3,
            ),
            child: MouseRegion(
              cursor: completions > 0
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onEnter: (_) {
                setState(() => _isHovered = true);
                _animationController.forward();
              },
              onExit: (_) {
                setState(() => _isHovered = false);
                _animationController.reverse();
              },
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  width: widget.cellSize,
                  height: widget.cellSize,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(2),
                    border: _isHovered
                        ? Border.all(color: Colors.green[800]!, width: 1.5)
                        : completions > 0
                        ? Border.all(color: Colors.green[600]!, width: 0.5)
                        : null,
                    boxShadow: [
                      if (completions > 0)
                        BoxShadow(
                          color: Colors.green.withOpacity(
                            0.3 + (0.4 * _glowAnimation.value),
                          ),
                          blurRadius: 2 + (4 * _glowAnimation.value),
                          offset: const Offset(0, 1),
                        ),
                      if (_isHovered)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: completions > 0 && widget.cellSize > 12
                      ? Center(
                          child: Text(
                            completions.toString(),
                            style: TextStyle(
                              fontSize: widget.cellSize * 0.5,
                              fontWeight: FontWeight.bold,
                              color: intensity > 0.5
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildDetailedTooltip() {
    final dayName = _getDayName(widget.date.weekday);
    final monthName = _getMonthName(widget.date.month);
    final dateStr =
        '$dayName, $monthName ${widget.date.day}, ${widget.date.year}';

    if (widget.dayData == null || widget.dayData!.totalCompletions == 0) {
      return '$dateStr\n\n📅 No tasks completed\n💡 Click to add tasks for this day';
    }

    final completions = widget.dayData!.totalCompletions;
    final taskCount = widget.dayData!.taskBreakdown.length;

    String message = '$dateStr\n\n✅ $completions task completion';
    if (completions != 1) message += 's';

    if (taskCount > 1) {
      message += '\n📊 Across $taskCount different tasks';
    }

    // Performance indicator
    final performance = _getPerformanceLevel(completions);
    message += '\n$performance';

    // Add task breakdown for detailed view
    if (widget.dayData!.taskBreakdown.isNotEmpty && taskCount <= 4) {
      message += '\n\n📋 Task Breakdown:';
      widget.dayData!.taskBreakdown.forEach((taskId, count) {
        message += '\n  • Task $taskId: $count completion';
        if (count != 1) message += 's';
      });
    }

    message += '\n\n💡 Click for more details';
    return message;
  }

  String _getPerformanceLevel(int completions) {
    if (completions >= 5) return '🔥 High productivity day!';
    if (completions >= 3) return '⭐ Good progress made';
    if (completions >= 1) return '👍 Task completed';
    return '';
  }

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
