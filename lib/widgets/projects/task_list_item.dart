import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/screens/task_breakdown_screen.dart';
import 'package:potential_aid_app/widgets/stats/progress_bar.dart';
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
  Future<void> _handleDeleteConfirmation(BuildContext context) async {
    if (widget.onDelete != null) {
      widget.onDelete!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final progress = task.endGoal > 0 ? task.current / task.endGoal : 0.0;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
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
      },
      onDismissed: (direction) {
        _handleDeleteConfirmation(context);
      },
      child: Card(
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
                      icon: const Icon(Icons.check_circle_outline, size: 20),
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
                      icon: const Icon(Icons.account_tree_rounded, size: 20),
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
    );
  }
}
