import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/widgets/timeline/auto_scroll_drag_handler.dart';
import 'package:time_machine/time_machine.dart' hide Offset;

class ResizableProjectInterval extends ConsumerStatefulWidget {
  final ProjectInterval project;
  final double dayCardWidth;
  final double projectBarHeight;
  final double handleWidth;
  final LocalDate timelineStart;
  final ScrollController? scrollController;
  final Function(ProjectInterval updatedProject) onProjectUpdated;

  const ResizableProjectInterval({
    required this.project,
    required this.dayCardWidth,
    required this.projectBarHeight,
    required this.handleWidth,
    required this.timelineStart,
    required this.onProjectUpdated,
    this.scrollController,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ResizableProjectIntervalState();
}

class _ResizableProjectIntervalState
    extends ConsumerState<ResizableProjectInterval>
    with AutoScrollMixin {
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  double _dragOffset = 0;
  double _cumulativeScrollOffset = 0;

  @override
  ScrollController? get scrollController => widget.scrollController;

  @override
  void initState() {
    super.initState();
    setScrollOffsetChangeCallback(_onScrollOffsetChanged);
  }

  void _onScrollOffsetChanged(double scrollDelta) {
    if (_isDraggingStart || _isDraggingEnd) {
      setState(() {
        _cumulativeScrollOffset += scrollDelta; // Track cumulative scroll
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final startPosition = _getDatePosition(
      widget.project.startDay,
      widget.timelineStart,
    );
    final endPosition = _getDatePosition(
      widget.project.endDay,
      widget.timelineStart,
    );

    final startX = startPosition * widget.dayCardWidth;
    final endX = (endPosition + 1) * widget.dayCardWidth;

    final dragDisplayStartX = _isDraggingStart
        ? startX + _dragOffset + _cumulativeScrollOffset
        : startX;
    final dragDisplayEndX = _isDraggingEnd
        ? endX + _dragOffset + _cumulativeScrollOffset
        : endX;
    final dragDisplayWidth = (dragDisplayEndX - dragDisplayStartX).clamp(
      40.0,
      double.infinity,
    ); // Minimum width of 40px

    return Row(
      children: [
        SizedBox(width: dragDisplayStartX),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: dragDisplayWidth,
              height: widget.projectBarHeight,
              decoration: BoxDecoration(
                color: widget.project.color,
                border: widget.project.progress != null
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (widget.project.progress != null)
                    Container(
                      width: dragDisplayWidth * widget.project.progress!,
                      height: widget.projectBarHeight,
                      decoration: BoxDecoration(
                        color: widget.project.color.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.project.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (dragDisplayWidth >
                            120) // Only show date if there's enough space
                          Text(
                            "${widget.project.startDay.monthOfYear}/${widget.project.startDay.dayOfMonth}-${widget.project.endDay.monthOfYear}/${widget.project.endDay.dayOfMonth}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragStart: (details) {
                  setState(() {
                    _isDraggingStart = true;
                    _dragOffset = 0;
                    _cumulativeScrollOffset = 0; // Reset scroll tracking
                  });
                  checkAutoScroll(details.globalPosition);
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragOffset += details.delta.dx;
                  });
                  // Use actual global position for auto-scroll detection
                  checkAutoScroll(details.globalPosition);
                },
                onHorizontalDragEnd: (details) async {
                  stopAutoScroll();
                  await _handleStartDateChange();
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: widget.handleWidth,
                    decoration: BoxDecoration(
                      color: _isDraggingStart
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 3,
                        height: widget.projectBarHeight * 0.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Right (end) handle
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragStart: (details) {
                  setState(() {
                    _isDraggingEnd = true;
                    _dragOffset = 0;
                    _cumulativeScrollOffset = 0; // Reset scroll tracking
                  });
                  checkAutoScroll(details.globalPosition);
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragOffset += details.delta.dx;
                  });
                  // Use actual global position for auto-scroll detection
                  checkAutoScroll(details.globalPosition);
                },
                onHorizontalDragEnd: (details) {
                  stopAutoScroll();
                  _handleEndDateChange();
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: widget.handleWidth,
                    decoration: BoxDecoration(
                      color: _isDraggingEnd
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 3,
                        height: widget.projectBarHeight * 0.5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _getDatePosition(LocalDate date, LocalDate timelineStart) {
    if (date < timelineStart) return 0;
    return date.periodSince(timelineStart).days;
  }

  Future<void> _handleStartDateChange() async {
    final totalOffset = _dragOffset + _cumulativeScrollOffset;
    final daysDelta = (totalOffset / widget.dayCardWidth).round();

    if (daysDelta == 0) {
      setState(() {
        _isDraggingStart = false;
        _dragOffset = 0;
        _cumulativeScrollOffset = 0;
      });
      return;
    }

    final newStartDay = widget.project.startDay.addDays(daysDelta);

    // Ensure minimum 1-day duration
    if (newStartDay.compareTo(widget.project.endDay) >= 0) {
      setState(() {
        _isDraggingStart = false;
        _dragOffset = 0;
        _cumulativeScrollOffset = 0;
      });
      return;
    }

    final updatedProject = ProjectInterval(
      projectId: widget.project.projectId,
      name: widget.project.name,
      startDay: newStartDay,
      endDay: widget.project.endDay,
      color: widget.project.color,
      progress: widget.project.progress,
    );

    await widget.onProjectUpdated(updatedProject);

    setState(() {
      _isDraggingStart = false;
      _dragOffset = 0;
      _cumulativeScrollOffset = 0;
    });
  }

  Future<void> _handleEndDateChange() async {
    // Include both drag offset and cumulative scroll offset for accurate position
    final totalOffset = _dragOffset + _cumulativeScrollOffset;
    final daysDelta = (totalOffset / widget.dayCardWidth).round();

    if (daysDelta == 0) {
      setState(() {
        _isDraggingEnd = false;
        _dragOffset = 0;
        _cumulativeScrollOffset = 0;
      });
      return;
    }

    final newEndDay = widget.project.endDay.addDays(daysDelta);

    // Ensure minimum 1-day duration
    if (newEndDay.compareTo(widget.project.startDay) <= 0) {
      setState(() {
        _isDraggingEnd = false;
        _dragOffset = 0;
        _cumulativeScrollOffset = 0;
      });
      return;
    }

    final updatedProject = ProjectInterval(
      projectId: widget.project.projectId,
      name: widget.project.name,
      startDay: widget.project.startDay,
      endDay: newEndDay,
      color: widget.project.color,
      progress: widget.project.progress,
    );

    await widget.onProjectUpdated(updatedProject);

    setState(() {
      _isDraggingEnd = false;
      _dragOffset = 0;
      _cumulativeScrollOffset = 0;
    });
  }
}
