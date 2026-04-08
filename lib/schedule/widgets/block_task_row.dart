import 'package:flutter/material.dart';
import 'package:potential_aid_app/data/database.dart';

/// Shared layout for a task line in schedule blocks and add/edit block dialogs.
class BlockTaskRow extends StatelessWidget {
  const BlockTaskRow({
    super.key,
    required this.task,
    this.trailing,
    this.dense = false,
  });

  final TaskData task;
  final Widget? trailing;
  final bool dense;

  static String? progressSubtitle(TaskData task) {
    if (task.endGoal <= 0) return null;
    final u = task.unit?.isNotEmpty == true ? ' ${task.unit}' : '';
    return '${task.current} / ${task.endGoal}$u';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final completed = task.isCompleted;
    final subtitle = progressSubtitle(task);

    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.3,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      decoration: completed ? TextDecoration.lineThrough : null,
      decorationColor: cs.onSurfaceVariant,
      color: completed ? cs.onSurfaceVariant : cs.onSurface,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      height: 1.2,
      color: cs.onSurfaceVariant,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: dense ? 6 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: completed ? cs.primary : cs.outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.name, style: titleStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: subtitleStyle),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
