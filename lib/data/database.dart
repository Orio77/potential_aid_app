import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:potential_aid_app/data/daos/block_dao.dart';
import 'package:potential_aid_app/data/daos/project_dao.dart';
import 'package:potential_aid_app/data/daos/task_dao.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/data/tables/block_completion.dart';
import 'package:potential_aid_app/data/tables/block_task.dart';
import 'package:potential_aid_app/data/tables/project.dart';
import 'package:potential_aid_app/data/tables/settings.dart';
import 'package:potential_aid_app/data/tables/task.dart';
import 'package:potential_aid_app/data/tables/task_completion.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Task,
    TaskCompletion,
    BlockCompletion,
    Block,
    BlockTask,
    Project,
    Settings,
  ],
  daos: [TaskDao, BlockDao, ProjectDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Since we're okay with losing test data, just recreate everything
      if (from < 16) {
        // Drop all tables and recreate them with the current schema
        await m.deleteTable('task_completion');
        await m.deleteTable('block_completion');
        await m.deleteTable('block_task');
        await m.deleteTable('block');
        await m.deleteTable('task');
        await m.deleteTable('project');
        await m.deleteTable('settings');

        // Recreate all tables with current schema
        await m.createAll();
      }
    },
    beforeOpen: (details) async {
      // Database will be reset via migration when schema version changes
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

  // Future<List<BlockWithTask>> getBlocksWithTasksForDate(DateTime date) async {
  //   final query = select(
  //     block,
  //   ).join([innerJoin(task, task.id.equalsExp(block.taskId))]);

  //   query.where(block.dayLocal.equals(date));
  //   query.orderBy([OrderingTerm.asc(block.startMinuteOfDay)]);

  //   final rows = await query.get();

  //   return rows.map((row) {
  //     final blockData = row.readTable(block);
  //     final taskData = row.readTable(task);

  //     return BlockWithTask(block: blockData);
  //   }).toList();
  // }

  Future<List<ProjectData>> getAllProjects() async {
    return await select(project).get();
  }

  Future<List<TaskData>> getAllTasks() async {
    return await (select(task)).get();
  }
}
