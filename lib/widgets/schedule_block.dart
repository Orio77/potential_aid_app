import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/providers/block_with_tasks_notifier.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/widgets/complete_block_dialog.dart';

class ScheduleBlock extends ConsumerWidget {
  final int blockId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ScheduleBlock({
    super.key,
    required this.blockId,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('ScheduleBlock.build() called for blockId: $blockId');
    final theme = Theme.of(context);
    final completionAsync = ref.watch(blockCompletionProvider(blockId));
    final AsyncValue<BlockWithTasks> blockAsync = ref.watch(
      blockTasksNotifier(blockId),
    );

    return completionAsync.when(
      data: (completionPercentage) {
        print(
          'ScheduleBlock blockId $blockId: completionPercentage = $completionPercentage',
        );
        return blockAsync.when(
          data: (block) =>
              _buildTaskBlock(context, theme, completionPercentage, block),
          error: (error, stack) => _buildTaskBlock(context, theme, 0.0, null),
          loading: () => _buildTaskBlock(context, theme, 0.0, null),
        );
      },
      loading: () {
        print('ScheduleBlock blockId $blockId: completion loading');
        return _buildTaskBlock(context, theme, 0.0, null);
      },
      error: (error, stack) {
        print('ScheduleBlock blockId $blockId: completion error: $error');
        return _buildTaskBlock(context, theme, 0.0, null);
      },
    );
  }

  Widget _buildTaskBlock(
    BuildContext context,
    ThemeData theme,
    double completionPercentage,
    BlockWithTasks? block,
  ) {
    print(
      'ScheduleBlock._buildTaskBlock() blockId $blockId: completionPercentage = $completionPercentage, isCompleted = ${completionPercentage > 0.0}',
    );
    final isCompleted = completionPercentage > 0.0;

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: Card(
        color: _getCardColor(theme, completionPercentage),
        child: InkWell(
          onTap: isCompleted ? null : onTap,
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
                        _buildProjectName(theme, completionPercentage, block),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTimeInfo(theme, block),
                            _buildTaskInfo(theme, block),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              _buildCompletionBadge(
                                theme,
                                completionPercentage,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(context, completionPercentage, block),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionIcon(ThemeData theme, double completionPercentage) {
    final isCompleted = completionPercentage > 0;

    if (isCompleted) {
      return Icon(
        Icons.check_circle,
        color: _getCompletionColor(completionPercentage),
        size: 24,
      );
    }

    return Icon(Icons.waves, color: theme.colorScheme.onSurfaceVariant);
  }

  Widget _buildProjectName(
    ThemeData theme,
    double completionPercentage,
    BlockWithTasks? block,
  ) {
    final isCompleted = completionPercentage > 0.0;
    final title = block?.tasks != null && block!.tasks!.isNotEmpty
        ? block.tasks!.first.name
        : 'Unnamed Block';

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskInfo(ThemeData theme, BlockWithTasks? block) {
    if (block == null) {
      return Text('block is null');
    }

    if (block.tasks == null) {
      return Text('tasks property is null');
    }

    final tasks = block.tasks!;

    if (tasks.isEmpty) {
      return Text(
        'No tasks (tasks list is empty)',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Show all tasks in a column - card will grow to fit content
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tasks
            .map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Text(
                  task.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCompletionBadge(ThemeData theme, double completionPercentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getCompletionColor(completionPercentage),
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
    double completionPercentage,
    BlockWithTasks? block,
  ) {
    final isCompleted = completionPercentage > 0.0;
    print(
      'ScheduleBlock._buildActionButton() blockId $blockId: completionPercentage = $completionPercentage, isCompleted = $isCompleted',
    );

    return IconButton(
      onPressed: isCompleted || block == null
          ? null
          : () {
              print(
                'ScheduleBlock: Opening CompleteTaskDialog for blockId $blockId',
              );
              showDialog(
                context: context,
                builder: (BuildContext buildContext) {
                  return CompleteTaskDialog(
                    blockId: block.block.id,
                    blockLength: block.block.lengthMinutes,
                  );
                },
              );
            },
      icon: Icon(
        isCompleted ? Icons.check_circle : Icons.task_alt,
        color: isCompleted
            ? Colors.grey
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Color? _getCardColor(ThemeData theme, double completionPercentage) {
    final isCompleted = completionPercentage > 0;

    if (!isCompleted) {
      return null;
    }

    return _getCompletionColor(completionPercentage).withValues(alpha: 0.1);
  }

  Color _getCompletionColor(double completionPercentage) {
    if (completionPercentage == 0) {
      return Colors.grey;
    } else if (completionPercentage < 25) {
      return Colors.red;
    } else if (completionPercentage < 50) {
      return Colors.orange;
    } else if (completionPercentage < 75) {
      return Colors.amber;
    } else if (completionPercentage < 100) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }
}
