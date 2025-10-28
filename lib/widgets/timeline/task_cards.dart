import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/providers/tasks_notifier.dart';
import 'package:potential_aid_app/providers/timeline_date_notifier.dart';
import 'package:potential_aid_app/screens/task_breakdown_screen.dart';
import 'package:potential_aid_app/widgets/timeline/task_card.dart';
import 'package:potential_aid_app/widgets/timeline/auto_scroll_drag_handler.dart';
import 'package:time_machine/time_machine.dart' hide Offset;

class TaskCards extends ConsumerStatefulWidget {
  final int? depth;
  final int? categoryId;
  final double dayCardWidth;
  final LocalDate timelineStart;
  final ScrollController? scrollController;
  final int? projectId;

  const TaskCards({
    super.key,
    required this.timelineStart,
    required this.dayCardWidth,
    this.depth,
    this.categoryId,
    this.scrollController,
    this.projectId,
  });

  @override
  ConsumerState<TaskCards> createState() => _TaskCardsState();
}

class _TaskCardsState extends ConsumerState<TaskCards> with AutoScrollMixin {
  late int depth;

  OverlayEntry? _dragOverlay;
  TaskData? _draggingTask;
  LocalDate? _originalDate;
  LocalDate? _hoveredDate;
  final GlobalKey _gridKey = GlobalKey();
  double _currentDragX = 0;
  double _currentDragY = 0;

  @override
  ScrollController? get scrollController => widget.scrollController;

  @override
  void initState() {
    super.initState();
    depth = widget.depth ?? 0;
    // Set up scroll offset change callback to update drag overlay position
    setScrollOffsetChangeCallback(_onScrollOffsetChanged);
  }

  @override
  void didUpdateWidget(TaskCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.depth != widget.depth) {
      setState(() {
        depth = widget.depth ?? 0;
      });
      // Reload tasks with new depth
      final currentMonth = ref.read(timelineDateNotifierProvider);
      ref
          .read(taskCardsNotifierProvider(depth).notifier)
          .loadTasksForMonth(
            monthDate: currentMonth,
            depth: depth,
            categoryId: widget.categoryId,
            projectId: widget.projectId,
          );
    }
  }

  void _onScrollOffsetChanged(double scrollDelta) {
    if (_dragOverlay != null && _draggingTask != null) {
      // Update the current drag position to account for scroll
      _currentDragX -= scrollDelta;
      _updateDragOverlay(_currentDragX, _currentDragY);
    }
  }

  @override
  void dispose() {
    _removeDragOverlay();
    super.dispose();
  }

  void _removeDragOverlay() {
    _dragOverlay?.remove();
    _dragOverlay = null;
    _draggingTask = null;
    _originalDate = null;
    _hoveredDate = null;
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(timelineDateNotifierProvider);
    final tasksByDate = ref.watch(taskCardsNotifierProvider(depth));

    ref.listen(timelineDateNotifierProvider, (previous, next) {
      if (previous != next) {
        ref
            .read(taskCardsNotifierProvider(depth).notifier)
            .loadTasksForMonth(
              monthDate: next,
              depth: depth,
              categoryId: widget.categoryId,
              projectId: widget.projectId,
            );
      }
    });

    if (tasksByDate.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(taskCardsNotifierProvider(depth).notifier)
            .loadTasksForMonth(
              monthDate: currentMonth,
              depth: depth,
              categoryId: widget.categoryId,
              projectId: widget.projectId,
            );
      });
    }

    return _buildTaskGrid(tasksByDate);
  }

  Widget _buildTaskGrid(Map<LocalDate, List<TaskData>> tasksByDate) {
    final datesInMonth = ref
        .read(timelineDateNotifierProvider.notifier)
        .getAllDaysInMonth();

    return Row(
      key: _gridKey,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: datesInMonth.map((date) {
        final tasksForDay = tasksByDate[date] ?? [];
        return _buildDayColumn(date, tasksForDay);
      }).toList(),
    );
  }

  Widget _buildDayColumn(LocalDate date, List<TaskData> tasks) {
    final isHovered = _hoveredDate == date;

    return Container(
      width: widget.dayCardWidth,
      decoration: BoxDecoration(
        color: isHovered
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isHovered ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...tasks.map((task) {
            final isBeingDragged =
                _draggingTask != null && _draggingTask!.id == task.id;

            return GestureDetector(
              onDoubleTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return TaskBreakdownScreen(task: task);
                    },
                  ),
                );
              },
              // Requirement 2: Shorter long press duration
              onLongPressStart: (details) =>
                  _onLongPressStart(details, task, date),
              onLongPressMoveUpdate: (details) {
                // Handle long press drag movement
                if (_draggingTask != null) {
                  _currentDragX = details.globalPosition.dx;
                  _currentDragY = details.globalPosition.dy;
                  _updateDragOverlay(_currentDragX, _currentDragY);

                  checkAutoScroll(details.globalPosition);

                  // Update hovered date for visual feedback
                  final hoveredDate = _getDateAtPosition(
                    details.globalPosition,
                  );
                  if (hoveredDate != _hoveredDate) {
                    setState(() {
                      _hoveredDate = hoveredDate;
                    });
                  }
                }
              },
              onLongPressEnd: (details) {
                // Handle long press drag end
                stopAutoScroll();

                if (_draggingTask != null && _originalDate != null) {
                  final dropDate = _getDateAtPosition(details.globalPosition);

                  if (dropDate != null && dropDate != _originalDate) {
                    _updateTaskDeadline(_draggingTask!, dropDate);
                  } else {
                    HapticFeedback.lightImpact();
                  }
                }

                setState(() {
                  _removeDragOverlay();
                });
              },
              onPanStart: (details) => _onPanStart(details, task, date),
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTap: () {
                // Only show details if not dragging
                if (_draggingTask == null) {
                  _showTaskDetails(task);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: isBeingDragged
                    ? _buildGhostTaskCard(
                        task,
                      ) // Requirement 3: Previous position visible in grey
                    : TaskCard(task: task, width: widget.dayCardWidth - 16),
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // Requirement 2: Handle shorter long press
  void _onLongPressStart(
    LongPressStartDetails details,
    TaskData task,
    LocalDate date,
  ) {
    // Provide haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _draggingTask = task;
      _originalDate = date;
    });

    _currentDragX = details.globalPosition.dx;
    _currentDragY = details.globalPosition.dy;
    _updateDragOverlay(_currentDragX, _currentDragY);

    // Start auto-scroll check immediately
    checkAutoScroll(details.globalPosition);
  }

  LocalDate? _getDateAtPosition(Offset globalPosition) {
    final RenderBox? renderBox =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final localPosition = renderBox.globalToLocal(globalPosition);
    final dayIndex = (localPosition.dx / widget.dayCardWidth).floor();

    final datesInMonth = ref
        .read(timelineDateNotifierProvider.notifier)
        .getAllDaysInMonth();

    if (dayIndex >= 0 && dayIndex < datesInMonth.length) {
      return datesInMonth[dayIndex];
    }

    return null;
  }

  Future<void> _updateTaskDeadline(TaskData task, LocalDate newDate) async {
    try {
      final newDeadline = newDate.toDateTimeUnspecified();
      await ref
          .read(tasksNotifierProvider(null).notifier)
          .updateTask(task.id, TaskCompanion(deadline: Value(newDeadline)));

      final currentMonth = ref.read(timelineDateNotifierProvider);
      await ref
          .read(taskCardsNotifierProvider(depth).notifier)
          .loadTasksForMonth(
            monthDate: currentMonth,
            depth: depth,
            categoryId: widget.categoryId,
            projectId: widget.projectId,
          );

      // Success feedback
      if (mounted) {
        // Strong haptic feedback for success
        HapticFeedback.heavyImpact();

        // Brief visual feedback (optional)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Moved to ${_formatDate(newDate)}'),
              ],
            ),
            duration: const Duration(milliseconds: 800), // Shorter duration
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
          ),
        );
      }
    } catch (e) {
      // Error feedback
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moving task: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(LocalDate date) {
    return '${date.monthOfYear}/${date.dayOfMonth}/${date.year}';
  }

  // Requirement 4: Enhanced drag overlay with better visual feedback
  void _updateDragOverlay(double x, double y) {
    if (_draggingTask == null) return;

    // Remove existing overlay if present
    _dragOverlay?.remove();

    _dragOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: x - (widget.dayCardWidth - 16) / 2,
          top: y - 30,
          child: Material(
            color: Colors.transparent,
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1.1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: TaskCard(
                      task: _draggingTask!,
                      width: widget.dayCardWidth - 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Insert overlay into the context
    Overlay.of(context).insert(_dragOverlay!);
  }

  void _onPanStart(DragStartDetails details, TaskData task, LocalDate date) {
    // Only start pan drag if not already dragging from long press
    if (_draggingTask != null) return;

    HapticFeedback.lightImpact();

    setState(() {
      _draggingTask = task;
      _originalDate = date;
    });

    _currentDragX = details.globalPosition.dx;
    _currentDragY = details.globalPosition.dy;
    _updateDragOverlay(_currentDragX, _currentDragY);
    checkAutoScroll(details.globalPosition); // Requirement 6: Auto-scroll
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragOverlay != null && _draggingTask != null) {
      _currentDragX = details.globalPosition.dx;
      _currentDragY = details.globalPosition.dy;
      _updateDragOverlay(_currentDragX, _currentDragY);

      // Requirement 6: Auto-scroll near edges with speed correlation
      checkAutoScroll(details.globalPosition);

      // Update hovered date for visual feedback
      final hoveredDate = _getDateAtPosition(details.globalPosition);
      if (hoveredDate != _hoveredDate) {
        setState(() {
          _hoveredDate = hoveredDate;
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    stopAutoScroll(); // Stop auto-scroll when drag ends

    if (_draggingTask != null && _originalDate != null) {
      final dropDate = _getDateAtPosition(details.globalPosition);

      if (dropDate != null && dropDate != _originalDate) {
        // Requirement 5: Move task to particular day
        _updateTaskDeadline(_draggingTask!, dropDate);
      } else {
        // Snap back animation if dropped in invalid location
        HapticFeedback.lightImpact();
      }
    }

    setState(() {
      _removeDragOverlay();
    });
  }

  // Requirement 3: Ghost card in grey color at previous position
  Widget _buildGhostTaskCard(TaskData task) {
    return Container(
      width: widget.dayCardWidth - 16,
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.8),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.drag_indicator,
              color: Colors.grey.withValues(alpha: 0.8),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              'Moving...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(TaskData task) {
    // Optional: Show task details on tap
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.deadline != null)
              Text(
                'Deadline: ${_formatDate(LocalDate.dateTime(task.deadline!))}',
              ),
            // Add other task properties as available
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
