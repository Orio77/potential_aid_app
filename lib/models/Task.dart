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
import 'package:potential_aid_app/models/project.dart';
import 'package:potential_aid_app/services/database.dart';

class Task extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get estimatedMinutes => integer()();
  IntColumn get projectId => integer()
      .references(Project, #id, onDelete: KeyAction.cascade)
      .nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class TaskWithStats {
  final TaskData task;
  final int totalMinutesCompleted;
  final double completionPercentage;
  final int blocksCount;
  final int completedBlocksCount;

  TaskWithStats({
    required this.task,
    required this.totalMinutesCompleted,
    required this.completionPercentage,
    required this.blocksCount,
    required this.completedBlocksCount,
  });

  bool get isOverEstimate => totalMinutesCompleted > task.estimatedMinutes;
  bool get hasTimeProgress => totalMinutesCompleted > 0;
  bool get isCompleteByTime => completionPercentage >= 100.0;
  bool get isCompleteByFlag => task.isCompleted;
  bool get isActuallyComplete => isCompleteByFlag || isCompleteByTime;

  String get statusDescription {
    if (isCompleteByFlag) return 'Completed';
    if (isCompleteByTime) return 'Time Complete';
    if (hasTimeProgress) return '${completionPercentage.round()}% done';
    return 'Not started';
  }
}

class TaskWithProject {
  final TaskData task;
  final ProjectData? project;

  TaskWithProject({required this.task, this.project});

  String get displayName => task.name;
  String get projectName => project?.name ?? 'No Project';
  bool get hasProject => project != null;
}
