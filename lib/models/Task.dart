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

class Task extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get estimatedMinutes => integer()();

  // TODO: Task 2.2 - Update Task model relationships
  // STEPS:
  // 1. Ensure projectId properly references Project table (add foreign key constraint)
  // 2. Add helper methods to get project information for tasks
  // 3. Update existing task creation to handle optional project assignment

  IntColumn get projectId => integer().nullable()();
  // TODO: Add foreign key constraint when Project table is implemented:
  // IntColumn get projectId => integer().nullable().references(Project, #id)();
}

// TODO: Task 2.3 - Create combined data models
// STEPS:
// 1. Create TaskWithProject class for displaying tasks with project context
// 2. Add helper methods for task-project relationships
// 3. Create data classes for UI consumption

// Example implementation (uncomment after Project model is ready):
// class TaskWithProject {
//   final TaskData task;
//   final ProjectData? project;
//   
//   TaskWithProject({
//     required this.task,
//     this.project,
//   });
//   
//   String get displayName => task.name;
//   String get projectName => project?.name ?? 'No Project';
//   bool get hasProject => project != null;
// }
