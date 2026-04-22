import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/projects/providers/task_progress_providers.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';
import 'package:potential_aid_app/stats/widgets/progress_bar.dart';

/// [ProjectProgressInfo] with the same first-depth task aggregate as the
/// project screen, so list/grid cards are not stuck at 0% when only tasks
/// store progress.
class ProjectTaskAwareProgressInfo extends ConsumerWidget {
  final ProjectData project;

  const ProjectTaskAwareProgressInfo({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      firstDepthTasksWithCompletedProvider(project.id),
    );
    return async.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return ProjectProgressInfo(project: project);
        }
        return ProjectProgressInfo(
          project: project,
          taskProgressFraction: aggregateRootTaskProgress(tasks),
        );
      },
      loading: () => ProjectProgressInfo(project: project),
      error: (e, s) => ProjectProgressInfo(project: project),
    );
  }
}

class ProjectProgressInfo extends StatelessWidget {
  final ProjectData project;

  /// When set, bar and % follow task aggregate (same as project screen with tasks).
  /// [project.current] is often 0 in that case.
  final double? taskProgressFraction;

  const ProjectProgressInfo({
    super.key,
    required this.project,
    this.taskProgressFraction,
  });

  @override
  Widget build(BuildContext context) {
    final title = project.name;
    final current = project.current;
    final goal = project.goal;
    final unit = project.unit;
    final fromTasks = taskProgressFraction != null;
    final safeFraction = fromTasks
        ? taskProgressFraction!.clamp(0.0, 1.0)
        : (goal > 0 ? current / goal : 0.0);
    final completionPercentage = safeFraction * 100;

    return _buildProgressSection(
      context,
      title,
      current,
      goal,
      unit,
      completionPercentage,
      fromTasks: fromTasks,
    );
  }
}

Widget _buildProgressSection(
  BuildContext context,
  String title,
  int current,
  int goal,
  String unit,
  double completionPercentage, {
  bool fromTasks = false,
}) {
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

      final pad = EdgeInsets.all(isVeryCompact ? 2.0 : (isCompact ? 4.0 : 8.0));
      final innerW = constraints.maxWidth.isFinite
          ? (constraints.maxWidth - pad.horizontal).clamp(0.0, double.infinity)
          : 200.0;

      Widget column = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
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
              child: fromTasks
                  ? Text(
                      '${completionPercentage.round()}%',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: progressColor,
                        fontSize: hasVeryTightHeight
                            ? 12
                            : (isVeryCompact ? 16 : (isCompact ? 20 : null)),
                      ),
                    )
                  : Row(
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
                                : (isVeryCompact
                                    ? 18
                                    : (isCompact ? 22 : null)),
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

            ProgressBar(
              completionValue: fromTasks
                  ? (completionPercentage / 100.0).clamp(0.0, 1.0)
                  : (goal > 0 ? current / goal : 0.0),
            ),
          ],
        );

      // Whenever height is bounded (grids, cards), scale down only if content
      // exceeds space — avoids overflow with text scaling or ProgressBar extras.
      if (constraints.hasBoundedHeight && innerW > 0) {
        column = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(width: innerW, child: column),
        );
      }

      return Padding(
        padding: pad,
        child: column,
      );
    },
  );
}
