import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/widgets/add_task_dialog.dart';
import 'package:potential_aid_app/widgets/projects/categories/add_to_category_button.dart';
import 'package:potential_aid_app/widgets/projects/delete_project.dart';
import 'package:potential_aid_app/widgets/projects/go_to_parent_button.dart';
import 'package:potential_aid_app/widgets/projects/link_project_dialog.dart';
import 'package:potential_aid_app/widgets/projects/project_info.dart';
import 'package:potential_aid_app/widgets/projects/project_task_list.dart';
import 'package:potential_aid_app/widgets/projects/project_title.dart';
import 'package:potential_aid_app/widgets/projects/related_projects_list.dart';
import 'package:potential_aid_app/widgets/stats/heatmap.dart';

class ProjectScreen extends ConsumerWidget {
  final ProjectData data;

  const ProjectScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: ProjectTitle(title: data.name),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leadingWidth: 120,
        leading: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_rounded),
            ),
            if (data.parentProjectId != null)
              GoToParentButton(parentId: data.parentProjectId!),
          ],
        ),
        actions: [
          AddToCategory(projectId: data.id, categoryId: data.category),
          DeleteProject(data: data),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProjectInfo(project: data),
            Heatmap(projectId: data.id),
            RelatedProjectsList(projectId: data.id),
            ProjectTaskList(projectId: data.id),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => showLinkProjectDialog(context, data.id),
            child: Icon(Icons.link_rounded),
          ),
          ElevatedButton(
            onPressed: () => showAddTaskDialog(context, data.id),
            child: Icon(Icons.add_task),
          ),
        ],
      ),
    );
  }
}
