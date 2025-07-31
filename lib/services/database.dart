import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:potential_aid_app/models/block.dart';
import 'package:potential_aid_app/models/settings.dart';
import 'package:potential_aid_app/models/task.dart';
import 'package:potential_aid_app/models/task_completion.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Task, TaskCompletion, Block, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'my_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  Future<List<BlockWithTask>> getBlocksWithTasksForDate(DateTime date) async {
    final query = select(
      block,
    ).join([innerJoin(task, task.id.equalsExp(block.taskId))]);

    query.where(block.dayLocal.equals(date));
    query.orderBy([OrderingTerm.asc(block.startMinuteOfDay)]);

    final rows = await query.get();

    return rows.map((row) {
      final blockData = row.readTable(block);
      final taskData = row.readTable(task);

      return BlockWithTask(
        block: blockData,
        taskName: taskData.name,
        taskEstimatedMinutes: taskData.estimatedMinutes,
      );
    }).toList();
  }
}
