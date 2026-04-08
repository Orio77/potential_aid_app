import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/schedule/providers/block_with_tasks_notifier.dart';
import 'package:potential_aid_app/schedule/widgets/block_completion_element.dart';
import 'package:potential_aid_app/schedule/widgets/task_completion_element.dart';

class CompleteBlockDialog extends ConsumerStatefulWidget {
  final int blockId;
  final int blockLength;

  const CompleteBlockDialog({
    super.key,
    required this.blockId,
    required this.blockLength,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CompleteBlockDialogState();
}

class _CompleteBlockDialogState extends ConsumerState<CompleteBlockDialog> {
  final List<GlobalKey<TaskCompletionElementState>> _taskKeys = [];
  final GlobalKey<BlockCompletionElementState> _blockKey =
      GlobalKey<BlockCompletionElementState>();
  late List<TaskData> tasks;
  late int minutesCompleted;

  @override
  Widget build(BuildContext context) {
    final blockWithTasksAsync = ref.watch(blockTasksNotifier(widget.blockId));
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.85).clamp(280.0, 400.0);

    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(
            'Complete this block',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            blockWithTasksAsync.when(
              data: (blockWithTasks) {
                if (blockWithTasks.tasks != null) {
                  _taskKeys.clear();
                  for (int i = 0; i < blockWithTasks.tasks!.length; i++) {
                    _taskKeys.add(GlobalKey<TaskCompletionElementState>());
                  }
                }

                final tasks = blockWithTasks.tasks;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BlockCompletionElement(
                          key: _blockKey,
                          block: blockWithTasks.block,
                          onBlockCompletion: (blockId, minutesCompleted) {},
                        ),
                        if (tasks != null && tasks.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                'Tasks',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${tasks.length}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme
                                        .colorScheme
                                        .onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          for (var i = 0; i < tasks.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            TaskCompletionElement(
                              key: _taskKeys[i],
                              task: tasks[i],
                              onTaskCompletion: (taskId, completionCount) {},
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
              error: (error, stack) => Text('Error: $error'),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 20, right: 12, left: 12),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            await _saveAllCompletions();
            if (mounted) {
              navigator.pop();
            }
          },
          child: const Text('Complete'),
        ),
      ],
    );
  }

  Future<void> _saveAllCompletions() async {
    final List<String> errors = [];

    for (int i = 0; i < _taskKeys.length; i++) {
      final key = _taskKeys[i];
      if (key.currentState != null) {
        try {
          final state = key.currentState as TaskCompletionElementState;
          await state.saveCompletion();
        } catch (e) {
          errors.add('Task ${i + 1}: $e');
        }
      }
    }

    if (_blockKey.currentState != null) {
      try {
        final state = _blockKey.currentState as BlockCompletionElementState;
        await state.saveCompletion();
      } catch (e) {
        errors.add("Block: $e");
      }
    }

    ref.invalidate(blockTasksNotifier(widget.blockId));
  }
}
