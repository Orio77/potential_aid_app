import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/widgets/delete_task_dialog.dart';
import 'package:potential_aid_app/widgets/edit_task_dialog.dart';
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
        ref
            .read(scheduleNotifierProvider.notifier)
            .reorderTasks(oldIndex, newIndex);
      },
    );
  }

  Widget _buildTaskPlaceholder(
    BuildContext context,
    BlockWithTask block,
    int index,
  ) {
    return Dismissible(
      key: ValueKey(block.block.id),
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
                return DeleteTaskDialog(blockId: block.block.id);
              },
            ) ??
            false;
      },
      child: TaskBlock(
        key: ValueKey(block.block.id), // Unique key for ReorderableListView
        block: block,
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return EditTaskDialog(
                blockId: block.block.id,
                taskId: block.block.taskId,
                initialTaskName: block.taskName,
                initialStartTime: block.block.startMinuteOfDay,
                initialDuration: block.block.lengthMinutes,
              );
            },
          );
        },
      ),
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
