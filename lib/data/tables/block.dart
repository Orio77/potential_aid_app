import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'task.dart';

class Block extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().references(Task, #id)();
  DateTimeColumn get dayLocal => dateTime()();
  IntColumn get startMinuteOfDay => integer()();
  IntColumn get lengthMinutes => integer()();
}

class BlockWithTask {
  final BlockData block;
  final String taskName;

  BlockWithTask({required this.block, required this.taskName});

  String get displayName => taskName.isEmpty ? "Unnamed task" : taskName;

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
