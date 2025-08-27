import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/utils/time_utils.dart';

class ProjectInfo extends ConsumerWidget {
  final ProjectData project;
  const ProjectInfo({required this.project, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = project.name;
    final current = project.current;
    final goal = project.goal;
    final unit = project.unit;
    final deadline = project.deadline;

    return Column(
      children: [
        Center(
          child: Text(
            title,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
        ),
        Text('$current / $goal $unit'),
        Text('Deadline: ${TimeUtils.formatDateTime(deadline)}'),
      ],
    );
  }
}
