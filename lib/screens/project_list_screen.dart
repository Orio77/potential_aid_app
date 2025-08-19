import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/widgets/projects/add_project_dialog.dart';
import 'package:potential_aid_app/widgets/projects/project_list.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Projects'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: Column(children: [Expanded(child: ProjectList())]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddProjectDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
