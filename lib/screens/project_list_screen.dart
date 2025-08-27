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
        title: const Text(
          'Projects',
          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 35),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: const SafeArea(
        child: Padding(padding: EdgeInsets.all(16), child: ProjectList()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showAddProjectDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Project'),
      ),
    );
  }
}
