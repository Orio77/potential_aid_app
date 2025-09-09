import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/stats_provider.dart';
import 'package:potential_aid_app/utils/time_utils.dart';
import 'package:potential_aid_app/widgets/projects/project_progress_info.dart';

class ProjectInfo extends ConsumerWidget {
  final ProjectData project;
  const ProjectInfo({required this.project, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(projectStatsNotifier(project.id));

    return statsAsync.when(
      data: (data) => _buildProjectStats(context, project, data),
      error: (error, stack) => _buildErrorState(context, error),
      loading: () => _buildLoadingState(),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.errorContainer,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Error loading stats: $error",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildProjectStats(
    BuildContext context,
    ProjectData project,
    ProjectStats stats,
  ) {
    final unit = project.unit;
    final deadline = project.deadline;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate days until deadline
    final now = DateTime.now();
    final daysUntilDeadline = deadline.difference(now).inDays;
    final isOverdue = daysUntilDeadline < 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerLow,
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Section
          ProjectProgressInfo(project: project),

          const SizedBox(height: 20),

          // Stats Grid
          _buildStatsGrid(
            context,
            deadline,
            daysUntilDeadline,
            isOverdue,
            stats,
            unit,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    DateTime deadline,
    int daysUntilDeadline,
    bool isOverdue,
    ProjectStats stats,
    String unit,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Stats cards in a grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              context,
              icon: isOverdue ? Icons.warning : Icons.schedule,
              label: 'Deadline',
              value: TimeUtils.formatDateTime(deadline),
              subtitle: isOverdue
                  ? '${daysUntilDeadline.abs()} days overdue'
                  : daysUntilDeadline == 0
                  ? 'Today!'
                  : '$daysUntilDeadline days left',
              isWarning: isOverdue,
              isUrgent: daysUntilDeadline <= 3 && daysUntilDeadline > 0,
            ),

            _buildStatCard(
              context,
              icon: Icons.access_time,
              label: 'Time Spent',
              value: _formatTimeSpent(stats.timeSpentTotal),
              subtitle: 'Total work time',
            ),

            _buildStatCard(
              context,
              icon: Icons.trending_up,
              label: 'Daily Average',
              value: stats.averageUnitPerDay.toStringAsFixed(1),
              subtitle: '$unit per day',
            ),

            _buildStatCard(
              context,
              icon: Icons.favorite,
              label: 'Life Devoted',
              value: '${stats.lifeDevoted.toStringAsFixed(1)}%',
              subtitle: 'Of your time',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    bool isWarning = false,
    bool isUrgent = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color cardColor;
    Color iconColor;
    Color textColor;

    if (isWarning) {
      cardColor = colorScheme.errorContainer;
      iconColor = colorScheme.error;
      textColor = colorScheme.onErrorContainer;
    } else if (isUrgent) {
      cardColor = colorScheme.tertiaryContainer;
      iconColor = colorScheme.tertiary;
      textColor = colorScheme.onTertiaryContainer;
    } else {
      cardColor = colorScheme.surfaceContainerHighest;
      iconColor = colorScheme.primary;
      textColor = colorScheme.onSurface;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeSpent(int totalMinutes) {
    if (totalMinutes < 60) {
      return '${totalMinutes}m';
    } else if (totalMinutes < 1440) {
      // Less than a day
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      final days = totalMinutes ~/ 1440;
      final hours = (totalMinutes % 1440) ~/ 60;
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
  }
}
