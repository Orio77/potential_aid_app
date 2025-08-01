import 'package:flutter/material.dart';
import 'package:potential_aid_app/widgets/projects/add_project_dialog.dart';

/// Floating action button for adding new projects.
///
/// This widget provides a consistent UI element for project creation
/// that follows the same patterns as other add buttons in the app.
class AddProjectButton extends StatelessWidget {
  const AddProjectButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const AddProjectDialog(),
        );
      },
      tooltip: 'Add Project',
      child: const Icon(Icons.add),
    );
  }
}
