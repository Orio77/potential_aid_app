import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/stats_provider.dart';
import 'package:potential_aid_app/utils/time_utils.dart';
import 'package:potential_aid_app/widgets/stats/progress_bar.dart';

class ProjectInfo extends ConsumerWidget {
  final ProjectData project;
  const ProjectInfo({required this.project, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = project.current;
    final goal = project.goal;
    final unit = project.unit;
    final deadline = project.deadline;
    final statsAsync = ref.watch(projectStatsNotifier(project.id));

    return statsAsync.when(
      data: (data) => _buildProjectStats(current, goal, unit, deadline, data),
      error: (error, stack) => Text("Error: $error"),
      loading: () => const CircularProgressIndicator(),
    );
  }

  Widget _buildProjectStats(
    int current,
    int goal,
    String unit,
    DateTime deadline,
    ProjectStats stats,
  ) {
    return Column(
      children: [
        Text('$current / $goal $unit'),
        ProgressBar(completionValue: current / goal),
        Text('Deadline: ${TimeUtils.formatDateTime(deadline)}'),
        Text("Time Spent Total: ${stats.timeSpentTotal}"),
        Text("Avg: ${stats.averageUnitPerDay} $unit per day"),
        Text("Life Devoted: ${stats.lifeDevoted}%"),
      ],
    );
  }
}
