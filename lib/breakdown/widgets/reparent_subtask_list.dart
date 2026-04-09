import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/breakdown/models/subtask_item.dart';
import 'package:potential_aid_app/breakdown/widgets/subtask_card.dart';

/// Subtask rows for reparent mode. Dropping on another row nests under that
/// task; dropping on the main task card (handled by the screen) promotes one level.
class ReparentSubtaskList extends StatelessWidget {
  final List<SubtaskItem> subtasks;
  final TaskData parentTask;
  final double subtasksWidth;
  final Function(int dragIndex, int targetIndex) onReparent;
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
      itemCount: subtasks.length,
      itemBuilder: (context, index) {
        final realIndex = index;
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

        // Draggable wraps DragTarget so the row's DragTarget is removed while dragging
        // (childWhenDragging replaces the subtree); the reverse broke drops on the main card.
        return LongPressDraggable<int>(
          key: Key(subtask.id),
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
          child: DragTarget<int>(
            onWillAcceptWithDetails: (d) =>
                d.data != realIndex && subtask.isExisting,
            onAcceptWithDetails: (d) => onReparent(d.data, realIndex),
            builder: (context, candidateData, _) {
              final hovered = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: hovered
                      ? Colors.deepPurple.withValues(alpha: 0.06)
                      : null,
                  boxShadow: hovered
                      ? [
                          BoxShadow(
                            color: Colors.deepPurple.withValues(alpha: 0.35),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
                child: card,
              );
            },
          ),
        );
      },
    );
  }
}
