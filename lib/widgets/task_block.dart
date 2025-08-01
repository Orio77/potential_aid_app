import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/models/block.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/widgets/complete_task_dialog.dart';

class TaskBlock extends ConsumerWidget {
  final BlockWithTask block;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TaskBlock({
    super.key,
    required this.block,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch the completion percentage for this specific block
    final completionAsync = ref.watch(blockCompletionProvider(block.block.id));

    return completionAsync.when(
      data: (completionPercentage) =>
          _buildTaskBlock(context, theme, completionPercentage),
      loading: () => _buildTaskBlock(
        context,
        theme,
        0.0,
      ), // Show as incomplete while loading
      error: (error, stack) =>
          _buildTaskBlock(context, theme, 0.0), // Show as incomplete on error
    );
  }

  Widget _buildTaskBlock(
    BuildContext context,
    ThemeData theme,
    double completionPercentage,
  ) {
    final isCompleted = completionPercentage > 0;

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: Card(
        color: _getCardColor(theme, completionPercentage),
        child: InkWell(
          onTap: isCompleted ? null : onTap,
          onLongPress: isCompleted ? null : onLongPress,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCompletionIcon(theme, completionPercentage),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskName(theme, completionPercentage),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildTimeInfo(theme),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            _buildCompletionBadge(theme, completionPercentage),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                _buildActionButton(context, completionPercentage),
              ],
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

  Widget _buildTaskName(ThemeData theme, double completionPercentage) {
    final isFullyCompleted = completionPercentage >= 100.0;

    return Text(
      block.taskName,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        decoration: isFullyCompleted ? TextDecoration.lineThrough : null,
        decorationColor: theme.colorScheme.onSurfaceVariant,
        color: isFullyCompleted
            ? theme.colorScheme.onSurfaceVariant
            : theme.textTheme.titleMedium?.color,
      ),
    );
  }

  Widget _buildTimeInfo(ThemeData theme) {
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

  Widget _buildActionButton(BuildContext context, double completionPercentage) {
    final isFullyCompleted = completionPercentage >= 100.0;

    return IconButton(
      onPressed: isFullyCompleted
          ? null
          : () {
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
        isFullyCompleted ? Icons.check_circle : Icons.task_alt,
        color: isFullyCompleted
            ? Colors.grey
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Color? _getCardColor(ThemeData theme, double completionPercentage) {
    final isCompleted = completionPercentage > 0;

    if (!isCompleted) {
      return null; // Default card color
    }

    // Return a subtle tinted background for completed tasks
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
