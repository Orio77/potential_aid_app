import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/breakdown/constants/task_breakdown_constants.dart';
import 'package:potential_aid_app/breakdown/widgets/subtask_buttons.dart';

/// The left-hand task card in the breakdown layout.
///
/// Pass [onDrop] for reparent mode: dropping a subtask on the card promotes it
/// to the same parent and depth as this task (sibling of this task).
class MainTaskCard extends StatelessWidget {
  final TaskData task;
  final GlobalKey cardKey;
  final VoidCallback onEdit;
  final VoidCallback onNavigateToProject;

  /// When non-null, the card becomes a [DragTarget<int>] that calls [onDrop]
  /// with the index of the dragged subtask.
  final Function(int)? onDrop;

  /// When [onDrop] is set, used to decide if a drag index may be dropped here
  /// (e.g. only persisted subtasks).
  final bool Function(int dragIndex)? onWillAcceptDrop;

  const MainTaskCard({
    super.key,
    required this.task,
    required this.cardKey,
    required this.onEdit,
    required this.onNavigateToProject,
    this.onDrop,
    this.onWillAcceptDrop,
  });

  @override
  Widget build(BuildContext context) {
    final card = _buildCard(context);
    if (onDrop == null) return card;

    return DragTarget<int>(
      hitTestBehavior: HitTestBehavior.opaque,
      onWillAcceptWithDetails: (details) =>
          onWillAcceptDrop?.call(details.data) ?? true,
      onAcceptWithDetails: (details) => onDrop!(details.data),
      builder: (context, candidateData, _) {
        final hovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: hovered
                ? Colors.deepPurple.withValues(alpha: 0.06)
                : null,
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: Colors.deepPurple.withValues(alpha: 0.45),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: card,
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    return SizedBox(
      width: TaskBreakdownConstants.mainTaskWidth,
      child: Center(
        child: Card(
          key: cardKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: TaskBreakdownConstants.maxTaskHeight,
                minHeight: TaskBreakdownConstants.minTaskHeight,
              ),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.parentTaskId != null)
                      GoToParentTaskButton(task: task),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          task.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: 'Edit task',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.folder_open, size: 18),
                          tooltip: 'Go to project',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onNavigateToProject,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
