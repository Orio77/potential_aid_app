import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/providers/block_with_tasks_notifier.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';
import 'package:potential_aid_app/widgets/complete_block_dialog.dart';
import 'package:potential_aid_app/widgets/edit_block_dialog.dart';
import 'package:potential_aid_app/widgets/schedule/blocks_task_list.dart';
import 'package:time_machine/time_machine.dart';

class ScheduleBlock extends ConsumerWidget {
  final int blockId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isPreviousBlockCompleted;

  const ScheduleBlock({
    super.key,
    required this.blockId,
    this.onTap,
    this.onLongPress,
    this.isPreviousBlockCompleted = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final completionAsync = ref.watch(
      blockCompletionPercentageProvider(blockId),
    );
    final AsyncValue<BlockWithTasks> blockAsync = ref.watch(
      blockTasksNotifier(blockId),
    );
    final projectAsync = ref.watch(projectByBlockProvider(blockId));
    final dateTime = ref.watch(dateTimeNotifierProvider);

    return blockAsync.when(
      data: (block) {
        return completionAsync.when(
          data: (completionPercentage) {
            return projectAsync.when(
              data: (project) => _buildTaskBlock(
                context,
                theme,
                completionPercentage,
                block,
                project!,
                dateTime,
                isPreviousBlockCompleted,
              ),
              error: (error, stack) {
                return _buildTaskBlock(
                  context,
                  theme,
                  null,
                  null,
                  null,
                  dateTime,
                  isPreviousBlockCompleted,
                );
              },
              loading: () {
                return _buildLoadingState(context, theme);
              },
            );
          },
          error: (error, stack) {
            return _buildErrorState(context, theme);
          },
          loading: () {
            return _buildLoadingState(context, theme);
          },
        );
      },
      loading: () {
        return _buildLoadingState(context, theme);
      },
      error: (error, stack) {
        return _buildErrorState(context, theme);
      },
    );
  }

  Widget _buildTaskBlock(
    BuildContext context,
    ThemeData theme,
    double? completionPercentage,
    BlockWithTasks? blockWithTasks,
    ProjectData? project,
    LocalDateTime dateTime,
    bool isPreviousBlockCompleted,
  ) {
    final isCompleted = completionPercentage != null;
    final isBlockInTheFuture =
        (blockWithTasks != null &&
        blockWithTasks.block.dayLocal.day > dateTime.dayOfMonth &&
        blockWithTasks.block.dayLocal.month >= dateTime.monthOfYear &&
        blockWithTasks.block.dayLocal.year >= dateTime.yearOfEra);

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: Card(
        color: _getCardColor(theme, completionPercentage),
        child: InkWell(
          onTap: isCompleted || !isBlockInTheFuture
              ? null
              : () => showEditBlockDialog(context, blockId: blockId),
          onLongPress: isCompleted ? null : onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _buildCompletionIcon(theme, completionPercentage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProjectName(theme, completionPercentage, project),
                        const SizedBox(height: 4),
                        _buildTimeInfo(theme, blockWithTasks),

                        if (blockWithTasks != null &&
                            blockWithTasks.tasks != null &&
                            blockWithTasks.tasks!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                        ],
                        BlocksTaskList(block: blockWithTasks),
                        if (isCompleted) ...[const SizedBox(width: 8)],
                      ],
                    ),
                  ),
                  _buildCompletionBadge(theme, completionPercentage),
                  _buildActionButton(
                    context,
                    completionPercentage,
                    blockWithTasks,
                    dateTime,
                    isPreviousBlockCompleted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionIcon(ThemeData theme, double? completionPercentage) {
    final isCompleted = completionPercentage != null;

    if (isCompleted) {
      return Icon(
        Icons.check_circle,
        color: CompletionUtils.getCompletionColor(completionPercentage),
        size: 24,
      );
    }

    return Icon(Icons.waves, color: theme.colorScheme.onSurfaceVariant);
  }

  Widget _buildProjectName(
    ThemeData theme,
    double? completionPercentage,
    ProjectData? project,
  ) {
    if (project == null) {
      return SizedBox.shrink();
    }
    final isCompleted = completionPercentage != null;
    final title = project.name;

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        decoration: isCompleted ? TextDecoration.lineThrough : null,
        decorationColor: theme.colorScheme.onSurfaceVariant,
        color: isCompleted
            ? theme.colorScheme.onSurfaceVariant
            : theme.textTheme.titleMedium?.color,
      ),
    );
  }

  Widget _buildTimeInfo(ThemeData theme, BlockWithTasks? block) {
    if (block == null) {
      return Text(
        'Loading...',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      children: [
        Text(
          block.formatTimeRange(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            block.formatDuration(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionBadge(ThemeData theme, double? completionPercentage) {
    return completionPercentage == null
        ? SizedBox.shrink()
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CompletionUtils.getCompletionColor(completionPercentage),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${completionPercentage.toInt()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          );
  }

  Widget _buildActionButton(
    BuildContext context,
    double? completionPercentage,
    BlockWithTasks? blockWithTasks,
    LocalDateTime dateTime,
    bool isPreviousBlockCompleted,
  ) {
    final isCompleted = completionPercentage != null;
    // Allow completion if: previous block is completed and it's on current day OR the block time has passed
    final isBlockToday =
        (blockWithTasks != null &&
        blockWithTasks.block.dayLocal.day == dateTime.dayOfMonth &&
        blockWithTasks.block.dayLocal.month == dateTime.monthOfYear &&
        blockWithTasks.block.dayLocal.year == dateTime.yearOfEra);
    final canComplete =
        blockWithTasks != null &&
        ((isPreviousBlockCompleted && isBlockToday) ||
            _isBlockTimePasssed(blockWithTasks, dateTime));

    return IconButton(
      onPressed: isCompleted || !canComplete
          ? null
          : () {
              showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return CompleteBlockDialog(
                    blockId: blockWithTasks.block.id,
                    blockLength: blockWithTasks.block.lengthMinutes,
                  );
                },
              );
            },
      icon: Icon(
        (isCompleted || !canComplete) ? Icons.check_circle : Icons.task_alt,
        color: (isCompleted || !canComplete)
            ? Colors.grey
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Color? _getCardColor(ThemeData theme, double? completionPercentage) {
    final isCompleted = completionPercentage != null;

    if (!isCompleted) {
      return null;
    }

    return CompletionUtils.getCompletionColor(
      completionPercentage,
    ).withValues(alpha: 0.1);
  }

  Widget _buildLoadingState(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text('Loading...', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 24),
            const SizedBox(width: 12),
            Text(
              'Error loading block',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isBlockTimePasssed(
    BlockWithTasks blockWithTasks,
    LocalDateTime currentTime,
  ) {
    final blockDate = blockWithTasks.block.dayLocal;
    final currentDate = currentTime.toDateTimeLocal();

    if (!_isSameDay(blockDate, currentDate)) {
      return false;
    }

    final currentMinutes =
        currentTime.hourOfDay * 60 + currentTime.minuteOfHour;
    final blockStartMinutes = blockWithTasks.block.startMinuteOfDay;

    return currentMinutes > blockStartMinutes;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
