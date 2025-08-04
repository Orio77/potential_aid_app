import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/models/block.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/services/database_completion.dart';
import 'package:potential_aid_app/widgets/delete_task_dialog.dart';
import 'package:potential_aid_app/widgets/task_block.dart';

class ScheduleList extends ConsumerWidget {
  const ScheduleList({super.key});

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.amberAccent),
          SizedBox(height: 16),
          Text('No tasks scheduled for this day'),
          Text('Tap the + button to add your first task'),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<BlockWithTask> blocks, WidgetRef ref) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: true,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return _buildTaskPlaceholder(context, block, index);
      },
      onReorder: (int oldIndex, int newIndex) async {
        // Check if the task being moved is completed
        final blockToMove = blocks[oldIndex];

        try {
          // Get the completion percentage directly from the database
          final database = ref.read(databaseProvider);
          final completionPercentage = await database
              .getBlockCompletionPercentage(blockToMove.block.id);

          final isCompleted = completionPercentage > 0;

          if (!isCompleted) {
            // Only allow reordering for incomplete tasks
            ref
                .read(scheduleNotifierProvider.notifier)
                .reorderTasks(oldIndex, newIndex);
          }
        } catch (error) {
          // On error, allow reordering (assume incomplete)
          ref
              .read(scheduleNotifierProvider.notifier)
              .reorderTasks(oldIndex, newIndex);
        }
      },
    );
  }

  Widget _buildTaskPlaceholder(
    BuildContext context,
    BlockWithTask block,
    int index,
  ) {
    return TaskBlock(
      key: ValueKey(block.block.id), // Unique key for ReorderableListView
      block: block,
      onTap: () {
        // TODO: Replace with: showEditTaskDialog(context, block)
        print(
          'Tapped task: ${block.block.id}',
        ); // Access block data through block.block
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return DeleteTaskDialog(blockId: block.block.id);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleData = ref.watch(scheduleNotifierProvider);

    return scheduleData.isEmpty
        ? _buildEmptyState()
        : _buildScheduleList(scheduleData, ref);
  }
}
