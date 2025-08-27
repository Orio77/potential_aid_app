import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/widgets/add_task_dialog.dart';
import 'package:potential_aid_app/widgets/projects/project_info.dart';
import 'package:potential_aid_app/widgets/projects/project_task_list.dart';

class ProjectScreen extends ConsumerWidget {
  final ProjectData data;

  const ProjectScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${data.name} Project"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Column(
        children: [
          ProjectInfo(project: data),
          Expanded(child: ProjectTaskList(projectId: data.id)),
        ],
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () => showAddTaskDialog(context, data.id),
        child: Icon(Icons.add_task),
      ),
    );
  }
}
