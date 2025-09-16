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

  return LayoutBuilder(
    builder: (context, constraints) {
      bool isVeryCompact =
          constraints.maxHeight < 100 || constraints.maxWidth < 200;
      bool isCompact =
          constraints.maxWidth < 300 || constraints.maxHeight < 150;

      final availableHeight = constraints.maxHeight;
      final hasVeryTightHeight = availableHeight < 90;

      return Padding(
        padding: EdgeInsets.all(isVeryCompact ? 2.0 : (isCompact ? 4.0 : 8.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontSize: hasVeryTightHeight
                          ? 10
                          : (isVeryCompact ? 12 : (isCompact ? 14 : null)),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: hasVeryTightHeight
                        ? 3
                        : (isVeryCompact ? 4 : (isCompact ? 6 : 8)),
                    vertical: hasVeryTightHeight
                        ? 0.5
                        : (isVeryCompact ? 1 : (isCompact ? 2 : 4)),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: progressColor.withValues(alpha: 0.1),
                  ),
                  child: Text(
                    CompletionUtils.getCompletionText(completionPercentage),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.w500,
                      fontSize: hasVeryTightHeight
                          ? 7
                          : (isVeryCompact ? 8 : (isCompact ? 10 : null)),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(
              height: hasVeryTightHeight
                  ? 1
                  : (isVeryCompact ? 2 : (isCompact ? 4 : 12)),
            ),

            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$current',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                      fontSize: hasVeryTightHeight
                          ? 14
                          : (isVeryCompact ? 18 : (isCompact ? 22 : null)),
                    ),
                  ),
                  Text(
                    ' / $goal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: hasVeryTightHeight
                          ? 10
                          : (isVeryCompact ? 12 : (isCompact ? 14 : null)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: hasVeryTightHeight
                          ? 8
                          : (isVeryCompact ? 10 : (isCompact ? 12 : null)),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: hasVeryTightHeight
                  ? 1
                  : (isVeryCompact ? 2 : (isCompact ? 4 : 8)),
            ),

            ProgressBar(completionValue: current / goal),
          ],
        ),
      );
    },
  );
}
