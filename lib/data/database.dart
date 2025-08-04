import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/data/tables/project.dart';
import 'package:potential_aid_app/data/tables/settings.dart';
import 'package:potential_aid_app/data/tables/task.dart';
import 'package:potential_aid_app/data/tables/task_completion.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Task, TaskCompletion, Block, Project, Settings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        // Add the task_completion table in version 2
        await m.createTable(taskCompletion);
      }
      if (from < 4) {
        // Add the project table in version 4
        await m.createTable(project);
      }
      if (from < 5) {
        // Remove estimated_minutes column from task table in version 5
        await m.deleteTable('task');
        await m.createTable(task);
      }
    },
    beforeOpen: (details) async {
      // For development: uncomment these lines to reset database on every restart
      // final db = details.database;
      // await db.execute('DROP TABLE IF EXISTS task');
      // await db.execute('DROP TABLE IF EXISTS task_completion');
      // await db.execute('DROP TABLE IF EXISTS block');
      // await db.execute('DROP TABLE IF EXISTS project');
      // await db.execute('DROP TABLE IF EXISTS settings');
    },
  );

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

      return BlockWithTask(block: blockData, taskName: taskData.name);
    }).toList();
  }

  Future<List<ProjectData>> getAllProjects() async {
    return await select(project).get();
  }
}
