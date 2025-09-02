import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/utils/time_utils.dart';

class ProjectInfo extends ConsumerWidget {
  final ProjectData project;
  const ProjectInfo({required this.project, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = project.current;
    final goal = project.goal;
    final unit = project.unit;
    final deadline = project.deadline;

    return Column(
      children: [
        Text('$current / $goal $unit'),
        Text('Deadline: ${TimeUtils.formatDateTime(deadline)}'),
        Text("Time spent total: 23h"), // TODO
        Text("Avg: 2 $unit / day"), // TODO
        Text("% of life devoted: 2.34%"), // TODO
      ],
    );
  }
}
