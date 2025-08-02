/*
 * TASK MODEL - EXTENDED WITH PROJECT SUPPORT
 * 
 * This file defines the Task table for the Drift database. Recently extended
 * to support optional project relationships as part of Phase 2 implementation.
 * 
 * RECENT CHANGES: Added projectId column to link tasks to projects.
 * Tasks can now belong to a project or be standalone (projectId = null).
 * 
 * TODO: Complete the project integration following tasks in projects_todo.md
 */

import 'package:drift/drift.dart';
import 'project.dart';

class Task extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get estimatedMinutes => integer()();

  /// Indicates whether the task has been completed.
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Timestamp for when the task was completed. Null if not completed yet.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Optional reference to the project this task belongs to.
  IntColumn get projectId =>
      integer().nullable().references(Project, #id, onDelete: KeyAction.setNull)();
}

// TODO: Task 2.3 - Create combined data models
// STEPS:
// 1. Create TaskWithProject class for displaying tasks with project context
// 2. Add helper methods for task-project relationships
// 3. Create data classes for UI consumption

// Example implementation (uncomment after Project model is ready):
class TaskWithProject {
  final TaskData task;
  final ProjectData? project;

  TaskWithProject({
    required this.task,
    this.project,
  });

  /// Convenience display name for the task.
  String get displayName => task.name;

  /// Returns the associated project name or a fallback when none exists.
  String get projectName => project?.name ?? 'No Project';

  /// Whether this task is part of a project.
  bool get hasProject => project != null;

  /// Whether the task has been completed.
  bool get isCompleted => task.isCompleted;

  /// Task completion timestamp if available.
  DateTime? get completedAt => task.completedAt;
}
