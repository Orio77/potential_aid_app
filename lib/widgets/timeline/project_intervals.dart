import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
import 'package:potential_aid_app/widgets/timeline/isolated_project_interval.dart';
import 'package:time_machine/time_machine.dart' hide Offset;

class ProjectIntervals extends ConsumerWidget {
  final List<ProjectInterval> projects;
  final double dayCardWidth;
  final LocalDate timelineStart;
  final ScrollController? scrollController;

  const ProjectIntervals({
    super.key,
    required this.projects,
    required this.dayCardWidth,
    required this.timelineStart,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildProjectIntervals(context, ref, projects);
  }

  Widget _buildProjectIntervals(
    BuildContext context,
    WidgetRef ref,
    List<ProjectInterval> projectList,
  ) {
    const projectBarHeight = 40.0;
    const spaceBetweenProjectIntervals = 8.0;
    const handleWidth = 20.0;

    projectList.sort((a, b) => b.endDay.compareTo(a.endDay));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...projectList.map((project) {
          if (project.projectId == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(
              bottom: spaceBetweenProjectIntervals,
            ),
            child: IsolatedProjectInterval(
              projectId: project.projectId!,
              dayCardWidth: dayCardWidth,
              projectBarHeight: projectBarHeight,
              handleWidth: handleWidth,
              timelineStart: timelineStart,
              scrollController: scrollController,
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
