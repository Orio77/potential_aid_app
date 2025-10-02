import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';

class ProjectIntervals extends ConsumerWidget {
  // final List<ProjectData> projectsData;
  final List<ProjectInterval> projects;
  final double dayCardHeight;
  final double dayCardWidth;
  const ProjectIntervals({
    super.key,
    required this.projects,
    // required this.projectsData,
    required this.dayCardHeight,
    required this.dayCardWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _buildProjectIntervals(context);
  }

  Widget _buildProjectIntervals(BuildContext context) {
    const projectBarHeight = 40.0;
    const spaceBetweenProjectIntervals = 8.0;

    // final projects = _createProjectIntervals(projectsData);

    projects.sort((a, b) => b.endDay.compareTo(a.endDay));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ...projects.map((project) {
          final startX = (project.startDay - 1) * dayCardWidth;
          final endX = project.endDay * dayCardWidth;
          final projectsWidth = endX - startX;

          return Padding(
            padding: const EdgeInsets.only(
              bottom: spaceBetweenProjectIntervals,
            ),
            child: Row(
              children: [
                SizedBox(width: startX),
                Container(
                  width: projectsWidth,
                  height: projectBarHeight,
                  decoration: BoxDecoration(
                    color: project.color,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "Day ${project.startDay}-${project.endDay}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16), // Bottom padding
      ],
    );
  }

  // ignore: unused_element
  List<ProjectInterval> _createProjectIntervals(
    List<ProjectData> projectsData,
  ) {
    return projectsData
        .map(
          (projectData) => ProjectInterval(
            name: projectData.name,
            startDay: projectData.startDate.day,
            endDay: projectData.deadline.day,
            color: Colors.lime,
          ),
        )
        .toList();
  }
}
