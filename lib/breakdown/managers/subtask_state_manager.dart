import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:uuid/uuid.dart';
import 'package:potential_aid_app/breakdown/models/subtask_item.dart';
import 'package:potential_aid_app/breakdown/constants/task_breakdown_constants.dart';

/// Manages the state of subtasks in the Task Breakdown Screen
class SubtaskStateManager {
  final List<SubtaskItem> _subtasks = [];
  final Uuid _uuid = const Uuid();

  List<SubtaskItem> get subtasks => List.unmodifiable(_subtasks);

  bool get isEmpty => _subtasks.isEmpty;
  int get length => _subtasks.length;

  /// Initialize with a single blank placeholder subtask, clearing any stale state.
  void initializeEmpty() {
    for (final subtask in _subtasks) {
      subtask.dispose();
    }
    _subtasks.clear();
    _subtasks.add(SubtaskItem.empty(_uuid.v4()));
  }

  /// Initialize with existing subtasks data
  void initializeFromData(
    List<({TaskData taskData, int subtaskCount})> subtasksData,
  ) {
    _subtasks.clear();
    for (final data in subtasksData) {
      _subtasks.add(
        SubtaskItem.fromTaskData(_uuid.v4(), data.taskData, data.subtaskCount),
      );
    }
  }

  /// Add a new empty subtask
  SubtaskItem addSubtask() {
    final newSubtask = SubtaskItem.empty(_uuid.v4());
    _subtasks.add(newSubtask);
    return newSubtask;
  }

  /// Remove subtask at index
  void removeSubtask(int index) {
    if (index >= 0 && index < _subtasks.length) {
      _subtasks[index].dispose();
      _subtasks.removeAt(index);
    }
  }

  /// Update subtask at index
  void updateSubtask(int index, SubtaskItem updatedSubtask) {
    if (index >= 0 && index < _subtasks.length) {
      _subtasks[index] = updatedSubtask;
    }
  }

  /// Get subtask at index safely
  SubtaskItem? getSubtask(int index) {
    if (index >= 0 && index < _subtasks.length) {
      return _subtasks[index];
    }
    return null;
  }

  /// Reorder subtasks
  void reorderSubtasks(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _subtasks.length ||
        newIndex < 0 ||
        newIndex >= _subtasks.length) {
      return;
    }

    final adjustedIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = _subtasks.removeAt(oldIndex);
    _subtasks.insert(adjustedIndex, item);
  }

  /// Check if reordering is allowed for the given indices
  bool canReorder(int oldIndex, int newIndex) {
    final oldItem = getSubtask(oldIndex);
    final newItem = getSubtask(newIndex);

    if (oldItem == null || newItem == null) return false;

    // Allow reordering of all subtasks (both new and existing)
    return true;
  }

  /// Get all valid subtasks (with content)
  List<SubtaskItem> getValidSubtasks() {
    return _subtasks.where((subtask) => subtask.hasValidContent).toList();
  }

  /// Dispose all resources
  void dispose() {
    for (final subtask in _subtasks) {
      subtask.dispose();
    }
    _subtasks.clear();
  }

  /// Calculate dynamic width based on content
  double calculateDynamicWidth(String mainTaskText) {
    final subtaskWidth = calculateDynamicSubtasksWidth();
    final mainTaskWidth = calculateDynamicMainTaskWidth(mainTaskText);

    return mainTaskWidth +
        subtaskWidth +
        TaskBreakdownConstants.spacing +
        TaskBreakdownConstants.padding;
  }

  /// Calculate dynamic subtasks width based on content
  double calculateDynamicSubtasksWidth() {
    double maxSubtaskWidth = TaskBreakdownConstants.subtasksWidth;

    for (final subtask in _subtasks) {
      if (subtask.controller.text.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: subtask.controller.text,
            style: const TextStyle(
              fontSize: TaskBreakdownConstants.subtaskFontSize,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final neededWidth =
            textPainter.width + TaskBreakdownConstants.textFieldPadding;
        maxSubtaskWidth = maxSubtaskWidth > neededWidth
            ? maxSubtaskWidth
            : neededWidth;
      }
    }

    // Add space for buttons and subtask count
    const buttonWidth = 15.0;
    const subtaskCountWidth = 32.0;
    const cardPadding = 16.0; // For left and right padding
    final buttonsSpace = TaskBreakdownConstants.numButtons * buttonWidth;

    return maxSubtaskWidth + buttonsSpace + subtaskCountWidth + cardPadding;
  }

  /// Calculate dynamic main task width based on content
  double calculateDynamicMainTaskWidth(String mainTaskText) {
    double dynamicMainTaskWidth = TaskBreakdownConstants.mainTaskWidth;
    final taskTextPainter = TextPainter(
      text: TextSpan(
        text: mainTaskText,
        style: const TextStyle(
          fontSize: TaskBreakdownConstants.mainTaskFontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    taskTextPainter.layout();
    final neededMainWidth =
        taskTextPainter.width + TaskBreakdownConstants.mainTaskTextPadding;
    return dynamicMainTaskWidth > neededMainWidth
        ? dynamicMainTaskWidth
        : neededMainWidth;
  }
}
