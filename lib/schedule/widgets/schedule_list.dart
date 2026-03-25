import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/block_with_tasks_notifier.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/widgets/projects/delete_task_dialog.dart';
import 'package:potential_aid_app/schedule/widgets/edit_block_dialog.dart';
import 'package:potential_aid_app/schedule/widgets/schedule_block.dart';

class ScheduleList extends ConsumerWidget {
  const ScheduleList({super.key});

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks scheduled for this day',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the + button to add your first task',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<int> blockIds, WidgetRef ref) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: blockIds.length,
      itemBuilder: (context, index) {
        final blockId = blockIds[index];
        final int? previousBlockId = index > 0 ? blockIds[index - 1] : null;
        return _buildBlockPlaceholder(
          context,
          ref,
          previousBlockId,
          blockId,
          index,
        );
      },
      onReorder: (int oldIndex, int newIndex) async {
        await ref
            .read(scheduleNotifierProvider.notifier)
            .reorderBlocks(oldIndex, newIndex);
        ref.invalidate(blockTasksNotifier(blockIds[oldIndex]));
        ref.invalidate(blockTasksNotifier(blockIds[newIndex]));
      },
    );
  }

  Widget _buildBlockPlaceholder(
    BuildContext context,
    WidgetRef ref,
    int? previousBlockId,
    int blockId,
    int index,
  ) {
    final completionAsync = ref.watch(
      blockCompletionPercentageProvider(blockId),
    );
    final previousCompletionAsync = previousBlockId != null
        ? ref.watch(blockCompletionPercentageProvider(previousBlockId))
        : const AsyncValue.data(1.0); // First block is always unlocked

    return completionAsync.when(
      data: (data) {
        return previousCompletionAsync.when(
          data: (previousData) {
            final isCompleted = data != null;
            final isPreviousCompleted =
                previousData != null || previousBlockId == null;

            if (isCompleted) {
              return Padding(
                key: ValueKey(blockId),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ScheduleBlock(
                  blockId: blockId,
                  isPreviousBlockCompleted: isPreviousCompleted,
                  onTap: () {
                    showEditBlockDialog(context, blockId: blockId);
                  },
                ),
              );
            } else {
              return Dismissible(
                key: ValueKey(blockId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 20,
                  ),
                  color: Colors.red,
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return DeleteBlockDialog(blockId: blockId);
                        },
                      ) ??
                      false;
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ScheduleBlock(
                    blockId: blockId,
                    isPreviousBlockCompleted: isPreviousCompleted,
                    onTap: () {
                      showEditBlockDialog(context, blockId: blockId);
                    },
                  ),
                ),
              );
            }
          },
          loading: () => Padding(
            key: ValueKey(blockId),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => Padding(
            key: ValueKey(blockId),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text("Error: $error"),
          ),
        );
      },
      loading: () => Padding(
        key: ValueKey(blockId),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: const CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Padding(
        key: ValueKey(blockId),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text("Error: $error"),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleData = ref.watch(scheduleNotifierProvider);

    return scheduleData.isEmpty
        ? _buildEmptyState(context)
        : _buildScheduleList(scheduleData, ref);
  }
}
