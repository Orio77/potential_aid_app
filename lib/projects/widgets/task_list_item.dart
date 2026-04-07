import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/breakdown/screens/task_breakdown_screen.dart';
import 'package:potential_aid_app/services/deadline_service.dart';
import 'package:potential_aid_app/projects/widgets/add_task_dialog.dart';
import 'package:potential_aid_app/projects/widgets/subtask_progress_section.dart';
import 'package:potential_aid_app/stats/widgets/progress_bar.dart';
import 'package:time_machine/time_machine.dart';

class TaskListItem extends ConsumerStatefulWidget {
  final TaskData task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;
  final bool editMode;
  final bool isSelected;

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
    this.onSelect,
    required this.editMode,
    this.isSelected = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskListItemState();
}

class _TaskListItemState extends ConsumerState<TaskListItem> {
  bool _isDismissed = false;
  bool _expanded = false;

  Future<void> _handleDeleteConfirmation(BuildContext context) async {
    if (widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final task = widget.task;
    final progress = task.endGoal > 0 ? task.current / task.endGoal : 0.0;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        color: Colors.blue,
        child: const Icon(
          Icons.edit_calendar_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await showDialog<bool>(
                context: context,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Delete Task'),
                    content: Text(
                      'Are you sure you want to delete "${task.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              ) ??
              false;
        }
        return true;
      },
      onDismissed: (direction) async {
        setState(() {
          _isDismissed = true;
        });

        if (direction == DismissDirection.endToStart) {
          _handleDeleteConfirmation(context);
        } else {
          await DeadlineService.moveTaskToTomorrow(
            ref: ref,
            context: context,
            task: task,
          );
        }
      },
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Main tile ─────────────────────────────────────────────
            InkWell(
              onLongPress: () async {
                await showAddTaskDialog(
                  context: context,
                  projectId: task.projectId,
                  taskData: task,
                );
              },
              child: ListTile(
                tileColor: widget.editMode && widget.isSelected
                    ? Theme.of(context).colorScheme.inversePrimary
                    : null,
                contentPadding: const EdgeInsets.all(16),
                onTap: widget.onTap,
                title: Text(
                  task.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ProgressBar(completionValue: progress),
                    const SizedBox(height: 4),
                    Text('${task.current}/${task.endGoal} ${task.unit}'),
                    Text(
                      'Deadline: ${task.deadline != null ? LocalDate.dateTime(task.deadline!).toString('dd-MM-yyyy') : 'No deadline set'}',
                    ),
                  ],
                ),
                trailing: widget.editMode
                    ? IconButton(
                        onPressed: () {
                          widget.onSelect?.call();
                        },
                        icon: Icon(
                          widget.isSelected
                              ? Icons.circle_rounded
                              : Icons.circle_outlined,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                            ),
                            onPressed: widget.onComplete,
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minHeight: 40,
                              minWidth: 40,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TaskBreakdownScreen(task: task),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.account_tree_rounded,
                              size: 20,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minHeight: 40,
                              minWidth: 40,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // ── Expand toggle ─────────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: _expanded
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Container(
                height: 22,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: _expanded
                      ? BorderRadius.zero
                      : const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                ),
                child: Center(
                  child: Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ),

            // ── Subtask progress (when expanded) ──────────────────────
            if (_expanded) SubtaskProgressSection(task: task),
          ],
        ),
      ),
    );
  }
}
