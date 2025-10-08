import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/screens/project_screen.dart';
import 'package:potential_aid_app/widgets/projects/project_progress_info.dart';
import 'package:potential_aid_app/widgets/projects/project_title.dart';
import 'package:potential_aid_app/utils/color_utils.dart';

class ProjectCard extends ConsumerWidget {
  final int projectId;
  const ProjectCard({super.key, required this.projectId});

  Widget _buildProjectCard(BuildContext context, ProjectData project) {
    final baseColor = project.color != null ? Color(project.color!) : null;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: baseColor == null
              ? null
              : ColorUtils.createDramaticNorthernLights(baseColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProjectScreen(data: project),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProjectTitle(title: project.name),
                const SizedBox(height: 8.0),
                ProjectProgressInfo(project: project),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectData = ref.watch(projectProvider(projectId));

    return projectData.when(
      data: (data) {
        if (data == null) {
          return const SizedBox.shrink();
        }
        return _buildProjectCard(context, data);
      },
      error: (error, stackTrace) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading project: $error'),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
