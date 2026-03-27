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

    return AlertDialog(
      title: const Center(
        child: Text('Complete This Block', textAlign: TextAlign.center),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            blockWithTasksAsync.when(
              data: (blockWithTasks) {
                if (blockWithTasks.tasks != null) {
                  _taskKeys.clear();
                  for (int i = 0; i < blockWithTasks.tasks!.length; i++) {
                    _taskKeys.add(GlobalKey<TaskCompletionElementState>());
                  }
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: Column(
                    children: [
                      BlockCompletionElement(
                        key: _blockKey,
                        block: blockWithTasks.block,
                        onBlockCompletion: (blockId, minutesCompleted) {},
                      ),
                      if (blockWithTasks.tasks != null) ...[
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: blockWithTasks.tasks!.length,
                          itemBuilder: (context, index) {
                            final task = blockWithTasks.tasks![index];
                            return TaskCompletionElement(
                              key: _taskKeys[index],
                              task: task,
                              onTaskCompletion: (taskId, completionCount) {},
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
              error: (error, stack) => Text('Error: $error'),
              loading: () => const CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
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
