import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/widgets/projects/project_card.dart';

class ProjectList extends ConsumerWidget {
  const ProjectList({super.key});

  Widget _buildEmptyState() {
    return Text("State is Empty");
  }

  Widget _buildProjectList(List<ProjectData> projects) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return ProjectCard(project: projects[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsData = ref.watch(projectsNotifierProvider);

    return projectsData.isEmpty
        ? _buildEmptyState()
        : _buildProjectList(projectsData);
  }
}
