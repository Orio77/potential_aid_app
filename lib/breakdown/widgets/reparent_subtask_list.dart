import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/breakdown/models/subtask_item.dart';
import 'package:potential_aid_app/breakdown/widgets/subtask_card.dart';

class ReparentSubtaskList extends StatelessWidget {
  final List<SubtaskItem> subtasks;
  final TaskData parentTask;
  final double subtasksWidth;
  final Function(int dragIndex, int targetIndex) onReparent;
  final Function(int dragIndex) onPromoteToRoot;
  final Function(int) onToggleSearch;
  final Function(int, TaskData) onSelectExistingTask;
  final Function(int) onRemove;
  final VoidCallback onSaveNeeded;
  final VoidCallback onComplete;
  final Function(String) onTextChanged;
  final Function(int)? onEdit;

  const ReparentSubtaskList({
    super.key,
    required this.subtasks,
    required this.parentTask,
    required this.subtasksWidth,
    required this.onReparent,
    required this.onPromoteToRoot,
    required this.onToggleSearch,
    required this.onSelectExistingTask,
    required this.onRemove,
    required this.onSaveNeeded,
    required this.onComplete,
    required this.onTextChanged,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // +1 for the project-root drop zone at index 0
      itemCount: subtasks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildProjectRootDropZone(context);

        final realIndex = index - 1;
        final subtask = subtasks[realIndex];

        final card = SubtaskCard(
          subtask: subtask,
          index: realIndex,
          parentTask: parentTask,
          onToggleSearch: onToggleSearch,
          onSelectExistingTask: onSelectExistingTask,
          onRemove: onRemove,
          onSaveNeeded: onSaveNeeded,
          onComplete: onComplete,
          onTextChanged: onTextChanged,
          onEdit: onEdit,
        );

        return DragTarget<int>(
          key: Key(subtask.id),
          onWillAcceptWithDetails: (d) => d.data != realIndex && subtask.isExisting,
          onAcceptWithDetails: (d) => onReparent(d.data, realIndex),
          builder: (context, candidateData, _) {
            final hovered = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: hovered
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple, width: 2),
                      color: Colors.deepPurple.withValues(alpha: 0.06),
                    )
                  : null,
              child: LongPressDraggable<int>(
                data: realIndex,
                delay: const Duration(milliseconds: 300),
                feedback: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: subtasksWidth * 0.85,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.deepPurple),
                    ),
                    child: Text(
                      subtask.controller.text,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.3, child: card),
                child: card,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectRootDropZone(BuildContext context) {
    return DragTarget<int>(
      key: const ValueKey('project_root_drop'),
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => onPromoteToRoot(d.data),
      builder: (context, candidateData, _) {
        final hovered = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hovered ? Colors.orange : Colors.grey.shade400,
              width: hovered ? 2 : 1,
            ),
            color: hovered
                ? Colors.orange.withValues(alpha: 0.10)
                : Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Icon(
                Icons.drive_file_move_outline,
                size: 18,
                color: hovered ? Colors.orange : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Move to project root (depth 0)',
                style: TextStyle(
                  fontSize: 13,
                  color: hovered ? Colors.orange.shade800 : Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
