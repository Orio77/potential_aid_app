import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/project.dart';

@TableIndex(name: 'idx_block_project_id', columns: {#projectId})
@TableIndex(name: 'idx_block_day_local', columns: {#dayLocal})
class Block extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId =>
      integer().references(Project, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get dayLocal => dateTime()();
  IntColumn get startMinuteOfDay => integer()();
  IntColumn get lengthMinutes => integer()();
}

class BlockWithTasks {
  final BlockData block;
  final List<TaskData>? tasks;

  BlockWithTasks({required this.block, this.tasks});

  String formatTimeRange() {
    final startMinutes = block.startMinuteOfDay;
    final endMinutes = startMinutes + block.lengthMinutes;
    final startHour = (startMinutes ~/ 60).toString().padLeft(2, '0');
    final startMin = (startMinutes % 60).toString().padLeft(2, '0');
    final endHour = (endMinutes ~/ 60).toString().padLeft(2, '0');
    final endMin = (endMinutes % 60).toString().padLeft(2, '0');
    return '$startHour:$startMin - $endHour:$endMin';
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
}
