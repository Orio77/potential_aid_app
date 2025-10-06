import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/providers/tasks_notifier.dart';
import 'package:potential_aid_app/providers/timeline_date_notifier.dart';
import 'package:potential_aid_app/widgets/timeline/task_card.dart';
import 'package:potential_aid_app/widgets/timeline/auto_scroll_drag_handler.dart';
import 'package:time_machine/time_machine.dart' hide Offset;

class TaskCards extends ConsumerStatefulWidget {
  final int? depth;
  final double dayCardWidth;
  final LocalDate timelineStart;
  final ScrollController? scrollController;

  const TaskCards({
    super.key,
    required this.timelineStart,
    required this.dayCardWidth,
    this.depth,
    this.scrollController,
  });

  @override
  ConsumerState<TaskCards> createState() => _TaskCardsState();
}

class _TaskCardsState extends ConsumerState<TaskCards> with AutoScrollMixin {
  late int depth;

  OverlayEntry? _dragOverlay;
  TaskData? _draggingTask;
  LocalDate? _originalDate;
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
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(timelineDateNotifierProvider);
    final tasksByDate = ref.watch(taskCardsNotifierProvider);

    ref.listen(timelineDateNotifierProvider, (previous, next) {
      if (previous != next) {
        ref
            .read(taskCardsNotifierProvider.notifier)
            .loadTasksForMonth(next, depth: depth);
      }
    });

    if (tasksByDate.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(taskCardsNotifierProvider.notifier)
            .loadTasksForMonth(currentMonth, depth: depth);
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
    return SizedBox(
      width: widget.dayCardWidth,
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...tasks.map((task) {
            final isBeingDragged =
                _draggingTask != null && _draggingTask!.id == task.id;

            return GestureDetector(
              onPanStart: (details) => _onPanStart(details, task, date),
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: isBeingDragged
                  ? _buildGhostTaskCard(task)
                  : TaskCard(task: task, width: widget.dayCardWidth - 16),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
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
          .read(taskCardsNotifierProvider.notifier)
          .loadTasksForMonth(currentMonth, depth: depth);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moving task: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _updateDragOverlay(double x, double y) {
    if (_dragOverlay == null || _draggingTask == null) return;

    _dragOverlay!.remove();
    _dragOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: x - (widget.dayCardWidth - 16) / 2,
          top: y - 30,
          child: Material(
            color: Colors.transparent,
            child: Transform.scale(
              scale: 1.1,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TaskCard(
                  task: _draggingTask!,
                  width: widget.dayCardWidth - 16,
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_dragOverlay!);
  }

  void _onPanStart(DragStartDetails details, TaskData task, LocalDate date) {
    setState(() {
      _draggingTask = task;
      _originalDate = date;
    });

    _currentDragX = details.globalPosition.dx;
    _currentDragY = details.globalPosition.dy;
    _updateDragOverlay(_currentDragX, _currentDragY);
    checkAutoScroll(details.globalPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragOverlay != null && _draggingTask != null) {
      _currentDragX = details.globalPosition.dx;
      _currentDragY = details.globalPosition.dy;
      _updateDragOverlay(_currentDragX, _currentDragY);
      checkAutoScroll(details.globalPosition);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    stopAutoScroll();
    if (_draggingTask != null && _originalDate != null) {
      final dropDate = _getDateAtPosition(details.globalPosition);

      if (dropDate != null && dropDate != _originalDate) {
        _updateTaskDeadline(_draggingTask!, dropDate);
      }
    }
    setState(() {
      _removeDragOverlay();
    });
  }

  Widget _buildGhostTaskCard(TaskData task) {
    return Container(
      width: widget.dayCardWidth - 16,
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.5),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          task.name,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.withValues(alpha: 0.7),
            fontStyle: FontStyle.italic,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
