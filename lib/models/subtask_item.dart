import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';

/// Model class representing a subtask item in the breakdown screen
class SubtaskItem {
  final String id;
  final TaskData? taskData;
  final TextEditingController controller;
  final FocusNode focusNode;
  final GlobalKey key;
  final bool isExisting;
  final int savedId;
  final int subtaskCount;
  final bool isSearchMode;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  SubtaskItem({
    required this.id,
    this.taskData,
    required this.controller,
    required this.focusNode,
    required this.key,
    required this.isExisting,
    required this.savedId,
    required this.subtaskCount,
    required this.isSearchMode,
    required this.searchController,
    required this.searchFocusNode,
  });

  /// Creates a new empty subtask item
  factory SubtaskItem.empty(String id) {
    return SubtaskItem(
      id: id,
      controller: TextEditingController(),
      focusNode: FocusNode(),
      key: GlobalKey(),
      isExisting: false,
      savedId: -1,
      subtaskCount: 0,
      isSearchMode: false,
      searchController: TextEditingController(),
      searchFocusNode: FocusNode(),
    );
  }

  /// Creates a subtask item from existing task data
  factory SubtaskItem.fromTaskData(
    String id,
    TaskData taskData,
    int subtaskCount,
  ) {
    return SubtaskItem(
      id: id,
      taskData: taskData,
      controller: TextEditingController(text: taskData.name),
      focusNode: FocusNode(),
      key: GlobalKey(),
      isExisting: true,
      savedId: taskData.id,
      subtaskCount: subtaskCount,
      isSearchMode: false,
      searchController: TextEditingController(),
      searchFocusNode: FocusNode(),
    );
  }

  /// Creates a copy of this subtask with updated properties
  SubtaskItem copyWith({
    String? id,
    TaskData? taskData,
    TextEditingController? controller,
    FocusNode? focusNode,
    GlobalKey? key,
    bool? isExisting,
    int? savedId,
    int? subtaskCount,
    bool? isSearchMode,
    TextEditingController? searchController,
    FocusNode? searchFocusNode,
  }) {
    return SubtaskItem(
      id: id ?? this.id,
      taskData: taskData ?? this.taskData,
      controller: controller ?? this.controller,
      focusNode: focusNode ?? this.focusNode,
      key: key ?? this.key,
      isExisting: isExisting ?? this.isExisting,
      savedId: savedId ?? this.savedId,
      subtaskCount: subtaskCount ?? this.subtaskCount,
      isSearchMode: isSearchMode ?? this.isSearchMode,
      searchController: searchController ?? this.searchController,
      searchFocusNode: searchFocusNode ?? this.searchFocusNode,
    );
  }

  /// Dispose resources
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
  }

  /// Check if this subtask has valid text content
  bool get hasValidContent => controller.text.trim().isNotEmpty;

  /// Check if this is a new unsaved subtask
  bool get isNew => !isExisting && savedId == -1;
}
