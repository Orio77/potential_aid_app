import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/screens/project_screen.dart';

class ProjectCard extends ConsumerWidget {
  final ProjectData project;
  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = project.name;
    final current = project.current;
    final goal = project.goal;
    final unit = project.unit;
    final deadline = project.deadline;

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
        child: Column(
          children: [
            Center(
              child: Text(
                name,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            Text('$current / $goal $unit'),
            Text(deadline.toString()),
          ],
        ),
      ),
    );
  }
}
