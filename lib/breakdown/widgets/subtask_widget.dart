import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/widgets/util/search_text_field.dart';
import 'package:potential_aid_app/models/subtask_item.dart';
import 'package:potential_aid_app/constants/task_breakdown_constants.dart';

/// Widget representing a single subtask item in the breakdown
class SubtaskWidget extends ConsumerWidget {
  final SubtaskItem subtaskItem;
  final int index;
  final TaskData parentTask;
  final VoidCallback onRemove;
  final VoidCallback onBreakdown;
  final Function(TaskData) onTaskSelected;
  final VoidCallback onToggleSearch;
  final VoidCallback onTextChanged;

  const SubtaskWidget({
    super.key,
    required this.subtaskItem,
    required this.index,
    required this.parentTask,
    required this.onRemove,
    required this.onBreakdown,
    required this.onTaskSelected,
    required this.onToggleSearch,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      key: subtaskItem.key,
      onLongPress: subtaskItem.isExisting ? null : onToggleSearch,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: subtaskItem.isSearchMode
                    ? _buildSearchField(ref)
                    : _buildTextField(),
              ),
              _buildSubtaskCountInfo(context),
              _buildBreakdownButton(),
              _buildRemoveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: subtaskItem.controller,
      focusNode: subtaskItem.focusNode,
      readOnly: subtaskItem.isExisting,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: 'Subtask ${index + 1}',
        fillColor: subtaskItem.isExisting ? Colors.grey : null,
        filled: subtaskItem.isExisting,
      ),
      onChanged: (_) => onTextChanged(),
    );
  }

  Widget _buildSearchField(WidgetRef ref) {
    return SearchTextField<TaskData, TaskSearchNotifier>(
      controller: subtaskItem.searchController,
      focusNode: subtaskItem.searchFocusNode,
      labelText: 'Search existing tasks',
      searchProvider: taskSearchProvider,
      getDisplayText: (task) => task.name,
      onItemSelected: onTaskSelected,
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
        // Note: This would need to be passed from parent for savedIds check
      ],
      maxResults: TaskBreakdownConstants.maxSearchResults,
    );
  }

  Widget _buildSubtaskCountInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 0, 0, 0),
      child: Container(
        width: TaskBreakdownConstants.subtaskCountCircleSize,
        height: TaskBreakdownConstants.subtaskCountCircleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Center(
          child: Text(
            subtaskItem.subtaskCount.toString(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: TaskBreakdownConstants.subtaskCountFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownButton() {
    return IconButton(
      onPressed: onBreakdown,
      icon: const Icon(Icons.account_tree_rounded),
    );
  }

  Widget _buildRemoveButton() {
    return IconButton(onPressed: onRemove, icon: const Icon(Icons.delete));
  }
}
