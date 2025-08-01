/*
 * PROJECTS SCREEN IMPLEMENTATION
 * 
 * This screen displays a list/grid of project cards and allows users to manage their projects.
 * Each project card shows basic information including name, deadline, task count, and progress.
 * 
 * CONTEXT: This is the main screen for the projects feature (Phase 2). Users will navigate
 * here from the main schedule screen to view and manage their projects.
 * 
 * ARCHITECTURE: Follows Flutter best practices with widget composition. Uses Riverpod for
 * state management and follows the same patterns established in MainScreen.
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/widgets/projects/project_list.dart';
import 'package:potential_aid_app/widgets/projects/add_project_button.dart';

// TODO: Task 4.1 - Create ProjectsScreen widget
// STEPS:
// -1. Create StatelessWidget extending ConsumerWidget for Riverpod integration
// -2. Implement app bar with title "Projects" and back button
// -3. Add search/filter functionality for projects (optional for first iteration)
// ?4. Handle empty state when no projects exist with helpful message
// ?5. Implement proper scrolling with RefreshIndicator
// ?6. Add error handling for loading failures

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: const Column(children: [Expanded(child: ProjectsList())]),
      floatingActionButton: const AddProjectButton(),
    );
  }
}
