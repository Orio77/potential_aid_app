import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/widgets/timeline/resizable_project_interval.dart';
import 'package:time_machine/time_machine.dart' hide Offset;

class ProjectIntervals extends ConsumerWidget {
  final List<ProjectInterval> projects;
  final double dayCardWidth;
  final LocalDate timelineStart;

  const ProjectIntervals({
    super.key,
    required this.projects,
    required this.dayCardWidth,
    required this.timelineStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildProjectIntervals(context);
  }

  Widget _buildProjectIntervals(BuildContext context) {
    const projectBarHeight = 40.0;
    const spaceBetweenProjectIntervals = 8.0;

    projects.sort((a, b) => b.endDay.compareTo(a.endDay));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...projects.asMap().entries.map((entry) {
          final index = entry.key;
          final project = entry.value;

          return Padding(
            padding: const EdgeInsets.only(
              bottom: spaceBetweenProjectIntervals,
            ),
            child: ResizableProjectInterval(
              project: project,
              dayCardWidth: dayCardWidth,
              projectBarHeight: projectBarHeight,
              handleWidth: 12.0,
              timelineStart: timelineStart,
              onProjectUpdated: (updatedProject) =>
                  print({"$index : $updatedProject"}),
            ),
          );
        }),
        const SizedBox(height: 16), // Bottom padding
      ],
    );
  }

  Future<void> _updateProject(ProjectInterval updatedProject) async {}
}
