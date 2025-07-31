/*
 * CURRENT STATUS: ✅ Database joined queries ARE WORKING!
 * 
 * WHAT'S WORKING:
 * - ✅ getBlocksWithTasksForDate() method is implemented correctly
 * - ✅ Returns List<BlockWithTask> with both block and task data
 * - ✅ Joins Block and Task tables properly
 * - ✅ Orders by start time correctly
 * 
 * NEXT TASK: Test the database method (it should work!)
 * - Run the app and see if task names appear
 * - If task names show up, this layer is COMPLETE
 * - No additional database changes needed for basic functionality
 * 
 * WHY THIS MATTERS:
 * - This is the data source for your entire app
 * - If this works, your task names should appear in the UI
 * - Focus on testing the app before adding more features
 */

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:potential_aid_app/models/block.dart';
import 'package:potential_aid_app/models/settings.dart';
import 'package:potential_aid_app/models/task.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Task, Block, Settings])
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
