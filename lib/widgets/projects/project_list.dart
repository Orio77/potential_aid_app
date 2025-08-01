import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/widgets/projects/project_card.dart';

// TODO: Task 4.4 - Implement project cards grid/list layout
// STEPS:
// 1. Create ProjectsList widget to display project cards
// 2. Use responsive layout (GridView.builder for tablets, ListView for phones)
// 3. Add proper spacing and margins
// 4. Handle different screen sizes with MediaQuery
// 5. Implement pull-to-refresh functionality
// 6. Add loading and error states
class ProjectsList extends ConsumerWidget {
  const ProjectsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final projectsAsync = ref.watch(projectsNotifierProvider);

    // TODO: Return different widgets based on state:
    // - Loading: CircularProgressIndicator
    // - Error: Error message with retry button
    // - Empty: EmptyProjectsWidget
    // - Data: GridView/ListView with ProjectCard widgets

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No projects yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to create your first project',
            style: TextStyle(color: Colors.grey),
          ),
          ProjectCard(),
        ],
      ),
    );
  }
}
