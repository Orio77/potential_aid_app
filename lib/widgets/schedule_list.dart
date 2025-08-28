import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/widgets/delete_task_dialog.dart';
import 'package:potential_aid_app/widgets/schedule_block.dart';

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
      buildDefaultDragHandles: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: blockIds.length,
      itemBuilder: (context, index) {
        final blockId = blockIds[index];
        return _buildBlockPlaceholder(context, blockId, index);
      },
      onReorder: (int oldIndex, int newIndex) async {
        ref
            .read(scheduleNotifierProvider.notifier)
            .reorderBlocks(oldIndex, newIndex);
      },
    );
  }

  Widget _buildBlockPlaceholder(BuildContext context, int blockId, int index) {
    return Dismissible(
      key: ValueKey(blockId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (BuildContext dialogContext) {
                return DeleteTaskDialog(blockId: blockId);
              },
            ) ??
            false;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ScheduleBlock(
          key: ValueKey(blockId), // Unique key for ReorderableListView
          blockId: blockId,
          onTap: () {
            // showDialog(
            //   context: context,
            //   builder: (BuildContext dialogContext) {
            //     return EditTaskDialog(
            //       blockId: block.block.id,
            //       taskId: block.block.projectId,
            //       initialTaskName: 'Change in schedule_list.dart',
            //       initialStartTime: block.block.startMinuteOfDay,
            //       initialDuration: block.block.lengthMinutes,
            //     );
            //   },
            // );
          },
        ),
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
