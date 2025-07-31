/*
 * SCHEDULE LIST WIDGET - REORDERABLELISTVIEW IMPLEMENTATION COMPLETE
 * 
 * This widget displays the list of scheduled tasks for the current day.
 * It's a core component that shows all tasks in chronological order
 * and supports drag-and-drop reordering.
 * 
 * IMPLEMENTED FEATURES:
 * ✅ ReorderableListView with proper drag-and-drop functionality
 * ✅ Automatic time recalculation after reordering
 * ✅ Unique keys for smooth reordering animation
 * ✅ Proper index adjustment for Flutter's reordering behavior
 * 
 * REMAINING TODOs:
 * - Replace print statements with proper edit task dialogs
 * - Add loading and error states
 * 
 * ARCHITECTURE CONTEXT:
 * - Connects to ScheduleNotifier for reactive data updates
 * - Handles empty state when no tasks are scheduled
 * - Supports reordering with automatic time recalculation
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/models/block.dart'; // For BlockWithTask
import 'package:potential_aid_app/providers/schedule_notifier.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return _buildTaskPlaceholder(context, block, index);
      },
      onReorder: (int oldIndex, int newIndex) {
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

    // TODO: Add loading and error states
    // Current implementation doesn't handle:
    // 1. Loading state while fetching data
    // 2. Error state if database query fails
    // 3. Refreshing/retry functionality
    // Should check if scheduleNotifierProvider has async states

    return scheduleData.isEmpty
        ? _buildEmptyState()
        : _buildScheduleList(scheduleData, ref);
  }
}
