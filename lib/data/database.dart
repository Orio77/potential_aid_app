import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:potential_aid_app/data/daos/project_dao.dart';
import 'package:potential_aid_app/data/daos/task_dao.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/data/tables/project.dart';
import 'package:potential_aid_app/data/tables/settings.dart';
import 'package:potential_aid_app/data/tables/task.dart';
import 'package:potential_aid_app/data/tables/task_completion.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Task, TaskCompletion, Block, Project, Settings],
  daos: [TaskDao, ProjectDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Since we're okay with losing test data, just recreate everything
      if (from < 13) {
        // Drop all tables and recreate them with the current schema
        await m.deleteTable('task_completion');
        await m.deleteTable('block');
        await m.deleteTable('task');
        await m.deleteTable('project');
        await m.deleteTable('settings');

        // Recreate all tables with current schema
        await m.createAll();
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

  Future<List<TaskData>> getAllTasks() async {
    return await (select(task)).get();
  }

  Future<int> getOrCreateTask(String taskName) async {
    // First, try to find an existing task with the same name
    final existingTaskQuery = select(task)
      ..where((t) => t.name.equals(taskName));

    final existingTasks = await existingTaskQuery.get();

    if (existingTasks.isNotEmpty) {
      // Task already exists, return its ID
      return existingTasks.first.id;
    }

    // Task doesn't exist, create a new one
    final newTask = TaskCompanion.insert(name: taskName);
    return await into(task).insert(newTask);
  }
}
