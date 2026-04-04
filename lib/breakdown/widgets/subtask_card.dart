import 'package:flutter/material.dart';
import 'package:potential_aid_app/breakdown/constants/task_breakdown_constants.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/breakdown/models/subtask_item.dart';
import 'package:potential_aid_app/breakdown/widgets/subtask_buttons.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';

/// Widget for displaying and editing a subtask card
class SubtaskCard extends StatelessWidget {
  final SubtaskItem subtask;
  final int index;
  final TaskData parentTask;
  final Function(int index) onToggleSearch;
  final Function(int index, TaskData task) onSelectExistingTask;
  final Function(int index) onRemove;
  final VoidCallback onSaveNeeded;
  final VoidCallback onComplete;
  final Function(String value) onTextChanged;
  final Function(int index)? onEdit;

  const SubtaskCard({
    super.key,
    required this.subtask,
    required this.index,
    required this.parentTask,
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
    final isSubtaskCompleted =
        subtask.taskData != null && subtask.taskData!.isCompleted;

    return Card(
      key: Key(subtask.id),
      color: isSubtaskCompleted ? Colors.greenAccent[100] : null,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: subtask.isSearchMode
                  ? _buildSearchField(context)
                  : _buildTextField(context, isSubtaskCompleted),
            ),
            SubtaskCountInfo(count: subtask.subtaskCount),
            CompleteTaskButton(
              subtask: subtask,
              parentTask: parentTask,
              onComplete: onComplete,
            ),
            ChangeDeadlineForTomorrowButton(subtask: subtask),
            if (onEdit != null && subtask.isExisting)
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Edit subtask',
                onPressed: () => onEdit!(index),
              ),
            ToggleSearchButton(
              subtask: subtask,
              onToggle: () => onToggleSearch(index),
            ),
            BreakdownSubtaskButton(
              subtask: subtask,
              parentTask: parentTask,
              onSaveNeeded: onSaveNeeded,
            ),
            RemoveSubtaskButton(onRemove: () => onRemove(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, bool isCompleted) {
    return TextField(
      controller: subtask.controller,
      focusNode: subtask.focusNode,
      readOnly: subtask.isExisting,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: 'Subtask ${index + 1}',
        fillColor: subtask.isExisting
            ? (isCompleted ? Colors.green[300] : Colors.grey[400])
            : null,
        filled: subtask.isExisting,
      ),
      onChanged: onTextChanged,
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return SearchTextField<TaskData, TaskSearchNotifier>(
      controller: subtask.searchController,
      focusNode: subtask.searchFocusNode,
      labelText: 'Search existing tasks',
      searchProvider: taskSearchProvider,
      getDisplayText: (task) => task.name,
      onItemSelected: (task) => onSelectExistingTask(index, task),
      leadingIcon: (task) =>
          const Icon(Icons.task_alt, size: 16, color: Colors.blue),
      trailingIcon: const Icon(
        Icons.arrow_forward_ios,
        size: 12,
        color: Colors.grey,
      ),
      predicates: [
        (task) => task.projectId == parentTask.projectId,
        (task) => !task.isCompleted,
        (task) => task.id != parentTask.id,
      ],
      maxResults: TaskBreakdownConstants.maxSearchResults,
    );
  }
}
