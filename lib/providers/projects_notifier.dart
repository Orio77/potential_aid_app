/*
 * PROJECTS STATE MANAGEMENT
 * 
 * This file manages the state for the projects feature using Riverpod and Drift.
 * It handles all project-related operations including CRUD operations, statistics,
 * and reactive updates when project data changes.
 * 
 * CONTEXT: Part of Phase 2 projects feature implementation. This notifier will manage
 * the projects list shown on the ProjectsScreen and handle project operations.
 * 
 * ARCHITECTURE: Follows the same patterns as ScheduleNotifier and SettingsNotifier,
 * using Riverpod StateNotifier with Drift for database operations and reactive streams.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:potential_aid_app/services/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

// TODO: Task 3.1 - Create ProjectsNotifier using Riverpod
// STEPS:
// 1. Create ProjectsNotifier class extending StateNotifier
// 2. Manage list of projects with statistics
// 3. Implement addProject method with validation
// 4. Implement editProject and deleteProject methods
// 5. Handle loading states and error handling
// 6. Use Drift streams for reactive updates
// 7. Create Riverpod provider for the notifier

// Example structure (uncomment and complete after Project model is ready):
// class ProjectsNotifier extends StateNotifier<List<ProjectWithStats>> {
//   final AppDatabase _database;
//   final Ref _ref;
//
//   ProjectsNotifier(this._database, this._ref) : super([]) {
//     _loadProjects();
//   }
//
//   Future<void> _loadProjects() async {
//     // Load projects with statistics from database
//     final projects = await _database.getProjectsWithStats();
//     state = projects;
//   }
//
//   Future<void> addProject(String name, DateTime deadline) async {
//     // Validate inputs
//     // Insert project to database
//     // Refresh state
//   }
//
//   Future<void> editProject(int id, String name, DateTime deadline) async {
//     // Update project in database
//     // Refresh state
//   }
//
//   Future<void> deleteProject(int id) async {
//     // Handle tasks that belong to this project
//     // Delete project from database
//     // Refresh state
//   }
// }

// TODO: Task 3.2 - Update existing notifiers to support projects
// STEPS:
// 1. Modify ScheduleNotifier.addTask to accept optional projectId parameter
// 2. Update task creation dialogs to include project selection
// 3. Ensure proper cleanup when projects are deleted
// 4. Update task display to show project information

// TODO: Task 3.3 - Create project-specific providers
// STEPS:
// 1. Create provider for getting tasks by project ID
// 2. Create provider for project statistics (task count, completion %)
// 3. Create provider for project deadline warnings

// final projectsNotifierProvider = StateNotifierProvider<ProjectsNotifier, List<ProjectWithStats>>((ref) {
//   final database = ref.watch(databaseProvider);
//   return ProjectsNotifier(database, ref);
// });

// final projectTasksProvider = FutureProvider.family<List<TaskData>, int>((ref, projectId) async {
//   final database = ref.watch(databaseProvider);
//   return database.getTasksForProject(projectId);
// });

// final projectStatsProvider = FutureProvider.family<ProjectStats, int>((ref, projectId) async {
//   final database = ref.watch(databaseProvider);
//   return database.getProjectStats(projectId);
// });
