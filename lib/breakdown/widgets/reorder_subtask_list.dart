import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/breakdown/models/subtask_item.dart';
import 'package:potential_aid_app/breakdown/widgets/subtask_card.dart';

class ReorderSubtaskList extends StatelessWidget {
  final List<SubtaskItem> subtasks;
  final TaskData parentTask;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(int) onToggleSearch;
  final Function(int, TaskData) onSelectExistingTask;
  final Function(int) onRemove;
  final VoidCallback onSaveNeeded;
  final VoidCallback onComplete;
  final Function(String) onTextChanged;
  final Function(int)? onEdit;

  const ReorderSubtaskList({
    super.key,
    required this.subtasks,
    required this.parentTask,
    required this.onReorder,
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
    return ReorderableListView.builder(
      shrinkWrap: true,
      buildDefaultDragHandles: false,
      itemCount: subtasks.length,
      itemBuilder: (context, index) {
        final subtask = subtasks[index];
        return Row(
          key: Key(subtask.id),
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_indicator, color: Colors.grey, size: 20),
              ),
            ),
            Expanded(
              child: SubtaskCard(
                subtask: subtask,
                index: index,
                parentTask: parentTask,
                onToggleSearch: onToggleSearch,
                onSelectExistingTask: onSelectExistingTask,
                onRemove: onRemove,
                onSaveNeeded: onSaveNeeded,
                onComplete: onComplete,
                onTextChanged: onTextChanged,
                onEdit: onEdit,
              ),
            ),
          ],
        );
      },
      onReorder: onReorder,
    );
  }
}
