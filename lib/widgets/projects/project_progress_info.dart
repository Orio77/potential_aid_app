import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';
import 'package:potential_aid_app/widgets/stats/progress_bar.dart';

class ProjectProgressInfo extends StatelessWidget {
  final ProjectData project;
  const ProjectProgressInfo({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final current = project.current;
    final goal = project.goal;
    final unit = project.unit;
    final completionPercentage = (current / goal);

    return _buildProgressSection(
      context,
      current,
      goal,
      unit,
      completionPercentage,
    );
  }
}

Widget _buildProgressSection(
  BuildContext context,
  int current,
  int goal,
  String unit,
  double completionPercentage,
) {
  final theme = Theme.of(context);
  final progressColor = CompletionUtils.getCompletionColorM3(
    completionPercentage,
    theme.colorScheme,
  );

  return Padding(
    padding: EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: progressColor.withValues(alpha: 0.1),
              ),
              child: Text(
                CompletionUtils.getCompletionText(completionPercentage),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$current',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
            Text(
              ' / $goal',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              unit,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        ProgressBar(completionValue: current / goal),
      ],
    ),
  );
}
