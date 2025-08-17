import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'task.dart';

@TableIndex(name: 'idx_block_task_id', columns: {#taskId})
@TableIndex(name: 'idx_block_day_local', columns: {#dayLocal})
class Block extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Task, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dayLocal => dateTime()();
  IntColumn get startMinuteOfDay => integer()();
  IntColumn get lengthMinutes => integer()();
  
  // TODO: Add position_in_block column for multiple tasks per block support
  // This column will be needed for the Add Block Dialog functionality
  // to support multiple tasks within a single time block.
  // 
  // Add this column:
  // IntColumn get positionInBlock => integer().withDefault(const Constant(0))();
  // 
  // This allows:
  // - Multiple block entries for the same time slot
  // - Tasks ordered by position (0, 1, 2, etc.)
  // - Proper task sequencing within blocks
  // - Support for task reordering
  //
  // After adding this column, you'll need to:
  // 1. Update the database schema version in database.dart
  // 2. Add migration logic to add this column to existing data
  // 3. Update all queries that create/read blocks to handle position
  // 4. Update BlockWithTask class to include position information
}

class BlockWithTask {
  final BlockData block;
  final String taskName;
  // TODO: Add position field when positionInBlock column is added to Block table
  // final int position;

  BlockWithTask({
    required this.block, 
    required this.taskName,
    // TODO: Add position parameter when implementing multiple tasks per block
    // required this.position,
  });

  String get displayName => taskName.isEmpty ? "Unnamed task" : taskName;

  // TODO: Update formatTimeRange for multiple tasks per block
  // When multiple tasks exist in a block, this should show:
  // - Individual task time slot within the block
  // - Or overall block time range with task position indicator
  String formatTimeRange() {
    final startMinutes = block.startMinuteOfDay;
    final endMinutes = startMinutes + block.lengthMinutes;
    final startHour = (startMinutes ~/ 60).toString().padLeft(2, '0');
    final startMin = (startMinutes % 60).toString().padLeft(2, '0');
    final endHour = (endMinutes ~/ 60).toString().padLeft(2, '0');
    final endMin = (endMinutes % 60).toString().padLeft(2, '0');
    return '$startHour:$startMin - $endHour:$endMin';
    
    // TODO: When position support is added, consider showing:
    // - Task-specific time slot: "$startHour:$startMin - $endHour:$endMin (Task ${position + 1})"
    // - Or block time with position: "$startHour:$startMin - $endHour:$endMin"
  }

  String formatDuration() {
    final minutes = block.lengthMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  // TODO: Add methods for multiple task block support
  // 
  // bool get isPartOfMultiTaskBlock => ...
  // int get totalTasksInBlock => ...
  // String get positionLabel => "Task ${position + 1}";
  // Duration get taskSpecificDuration => ...
}
