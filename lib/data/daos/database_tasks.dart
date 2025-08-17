/*
 * DATABASE EXTENSION FOR TASK-PROJECT OPERATIONS
 * 
 * This file extends the AppDatabase with methods specifically for handling
 * task operations related to projects. This is crucial for the Add Block Dialog
 * feature where users need to:
 * 1. Select a project
 * 2. View and search tasks within that project  
 * 3. Select multiple tasks for a time block
 * 
 * This extension provides the foundation for project-based task filtering
 * and searching functionality required by the Add Block Dialog.
 */

import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';

extension AppDatabaseTasks on AppDatabase {
  // TODO: Implement getTasksForProject method
  // This method should:
  // - Accept a projectId parameter
  // - Return List<TaskData> for tasks belonging to the specified project
  // - Filter out completed tasks (isCompleted = false)
  // - Order tasks by name alphabetically
  // Example: Future<List<TaskData>> getTasksForProject(int projectId) async { ... }

  // TODO: Implement searchTasksInProject method  
  // This method should:
  // - Accept projectId and searchQuery parameters
  // - Return List<TaskData> filtered by project and matching search query
  // - Use case-insensitive search on task name
  // - Limit results to maximum 5-10 items for performance
  // - Filter out completed tasks
  // Example: Future<List<TaskData>> searchTasksInProject(int projectId, String query) async { ... }

  // TODO: Implement addTaskToProject method
  // This method should:
  // - Accept taskName and projectId parameters
  // - Create a new task and associate it with the specified project
  // - Return the newly created task ID
  // - Handle duplicate task names within the same project
  // Example: Future<int> addTaskToProject(String taskName, int projectId) async { ... }

  // TODO: Implement getProjectWithTaskCount method
  // This method should:
  // - Return projects with their associated task counts
  // - Join Project and Task tables
  // - Count non-completed tasks only
  // - Return custom data structure with project info + task count
  // Example: Future<List<ProjectWithTaskCount>> getProjectWithTaskCount() async { ... }
}

// TODO: Create data class for ProjectWithTaskCount
// This should contain:
// - ProjectData project
// - int taskCount
// - bool hasIncompleteTasks
// Example:
// class ProjectWithTaskCount {
//   final ProjectData project;
//   final int taskCount;
//   final bool hasIncompleteTasks;
//   
//   ProjectWithTaskCount({
//     required this.project,
//     required this.taskCount, 
//     required this.hasIncompleteTasks,
//   });
// }
