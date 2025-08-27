import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/screens/project_screen.dart';
import 'package:potential_aid_app/widgets/projects/project_info.dart';

class ProjectCard extends ConsumerWidget {
  final ProjectData project;
  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProjectScreen(data: project),
            ),
          );
        },
        child: ProjectInfo(project: project),
      ),
    );
  }
}
