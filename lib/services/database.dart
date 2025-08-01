/*
 * DATABASE SERVICE - EXTENDED WITH PROJECTS SUPPORT
 * 
 * This file contains the main Drift database configuration and query methods.
 * Recently extended to support the Projects feature as part of Phase 2 implementation.
 * 
 * RECENT CHANGES: Added Project table to support project organization of tasks.
 * Projects have names, deadlines, and can group multiple tasks together.
 * 
 * TODO: Complete the projects integration following the tasks in projects_todo.md
 */

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:potential_aid_app/models/block.dart';
import 'package:potential_aid_app/models/project.dart';
import 'package:potential_aid_app/models/settings.dart';
import 'package:potential_aid_app/models/task.dart';
import 'package:potential_aid_app/models/task_completion.dart';

part 'database.g.dart';

// TODO: Task 1.1 - Add Project to tables list after implementing Project model
// TODO: Task 1.2 - Update schema version and add migration for Project table
@DriftDatabase(tables: [Task, TaskCompletion, Block, Project, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        // Add the task_completion table in version 2
        await m.createTable(taskCompletion);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  Future<List<BlockWithTask>> getBlocksWithTasksForDate(DateTime date) async {
    final query = select(
      block,
    ).join([innerJoin(task, task.id.equalsExp(block.taskId))]);

    query.where(block.dayLocal.equals(date));
    query.orderBy([OrderingTerm.asc(block.startMinuteOfDay)]);

    final rows = await query.get();

    return rows.map((row) {
      final blockData = row.readTable(block);
      final taskData = row.readTable(task);

      return BlockWithTask(
        block: blockData,
        taskName: taskData.name,
        taskEstimatedMinutes: taskData.estimatedMinutes,
      );
    }).toList();
  }

  // TODO: Task 1.3 - Extend database with project-related queries
  // STEPS:
  // 1. Add method to get all projects: Future<List<ProjectData>> getAllProjects()
  // 2. Add method to get projects with task counts: Future<List<ProjectWithStats>> getProjectsWithStats()
  // 3. Add method to get tasks for specific project: Future<List<TaskData>> getTasksForProject(int projectId)
  // 4. Add CRUD methods: insertProject, updateProject, deleteProject
  // 5. Add method to get tasks with project info for schedule screen

  // Example implementation (uncomment and complete after Project model is ready):
  // Future<List<ProjectData>> getAllProjects() async {
  //   return await select(project).get();
  // }

  // Future<List<ProjectWithStats>> getProjectsWithStats() async {
  //   // Join projects with task counts and completion statistics
  //   // This will be used by the ProjectsScreen to show project cards
  // }
}
