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
import 'package:potential_aid_app/data/tables/project_category.dart';
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
    ProjectCategory,
    Settings,
  ],
  daos: [TaskDao, BlockDao, ProjectDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 23;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 23) {
        // Create the project category table (includes orderIndex in the table definition)
        await m.createTable(projectCategory);
        await m.addColumn(project, project.category);
      }
      if (from < 19) {
        await m.addColumn(task, task.parentTaskId);
        await m.addColumn(task, task.orderIndex);
        await m.addColumn(task, task.depth);
      }
      if (from < 18) {
        await m.addColumn(project, project.parentProjectId);
      }
      if (from < 16) {
        await m.deleteTable('task_completion');
        await m.deleteTable('block_completion');
        await m.deleteTable('block_task');
        await m.deleteTable('block');
        await m.deleteTable('task');
        await m.deleteTable('project');
        await m.deleteTable('settings');

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
}
