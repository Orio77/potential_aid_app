import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/models/project_interval.dart';
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
        ...projects.map((project) {
          final startPosition = _getDatePosition(
            project.startDay,
            timelineStart,
          );
          final endPosition = _getDatePosition(project.endDay, timelineStart);

          final startX = startPosition * dayCardWidth;
          final endX = (endPosition + 1) * dayCardWidth;
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
                    border: project.progress != null
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (project.progress != null)
                        Container(
                          width: projectsWidth * project.progress!,
                          height: projectBarHeight,
                          decoration: BoxDecoration(
                            color: project.color.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      Padding(
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
                              "${project.startDay.monthOfYear}/${project.startDay.dayOfMonth}-${project.endDay.monthOfYear}/${project.endDay.dayOfMonth}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

  int _getDatePosition(LocalDate date, LocalDate timelineStart) {
    if (date < timelineStart) return 0;
    return date.periodSince(timelineStart).days;
  }
}
