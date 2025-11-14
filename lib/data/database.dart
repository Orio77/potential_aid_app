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
  int get schemaVersion => 26;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 26) {
        // Add sync columns to all tables using custom SQL

        // Task table
        await customStatement('ALTER TABLE task ADD COLUMN supabase_id TEXT');
        await customStatement(
          'ALTER TABLE task ADD COLUMN last_modified INTEGER NOT NULL DEFAULT (strftime("%s", "now"))',
        );
        await customStatement(
          'ALTER TABLE task ADD COLUMN needs_sync INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE task ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE task ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );

        // Project table
        await customStatement(
          'ALTER TABLE project ADD COLUMN supabase_id TEXT',
        );
        await customStatement(
          'ALTER TABLE project ADD COLUMN last_modified INTEGER NOT NULL DEFAULT (strftime("%s", "now"))',
        );
        await customStatement(
          'ALTER TABLE project ADD COLUMN needs_sync INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE project ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE project ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );

        // ProjectCategory table
        await customStatement(
          'ALTER TABLE project_category ADD COLUMN supabase_id TEXT',
        );
        await customStatement(
          'ALTER TABLE project_category ADD COLUMN last_modified INTEGER NOT NULL DEFAULT (strftime("%s", "now"))',
        );
        await customStatement(
          'ALTER TABLE project_category ADD COLUMN needs_sync INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE project_category ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE project_category ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );

        // Block table
        await customStatement('ALTER TABLE block ADD COLUMN supabase_id TEXT');
        await customStatement(
          'ALTER TABLE block ADD COLUMN last_modified INTEGER NOT NULL DEFAULT (strftime("%s", "now"))',
        );
        await customStatement(
          'ALTER TABLE block ADD COLUMN needs_sync INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE block ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE block ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );

        // TaskCompletion table
        await customStatement(
          'ALTER TABLE task_completion ADD COLUMN supabase_id TEXT',
        );
        await customStatement(
          'ALTER TABLE task_completion ADD COLUMN last_modified INTEGER NOT NULL DEFAULT (strftime("%s", "now"))',
        );
        await customStatement(
          'ALTER TABLE task_completion ADD COLUMN needs_sync INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE task_completion ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE task_completion ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );

        // BlockCompletion table
        await customStatement(
          'ALTER TABLE block_completion ADD COLUMN supabase_id TEXT',
        );
        await customStatement(
          'ALTER TABLE block_completion ADD COLUMN last_modified INTEGER NOT NULL DEFAULT (strftime("%s", "now"))',
        );
        await customStatement(
          'ALTER TABLE block_completion ADD COLUMN needs_sync INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE block_completion ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE block_completion ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );

        // BlockTask table
        await customStatement(
          'ALTER TABLE block_task ADD COLUMN supabase_id TEXT',
        );
        await customStatement(
          'ALTER TABLE block_task ADD COLUMN last_modified INTEGER NOT NULL DEFAULT (strftime("%s", "now"))',
        );
        await customStatement(
          'ALTER TABLE block_task ADD COLUMN needs_sync INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE block_task ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE block_task ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );

        // Settings table
        await customStatement(
          'ALTER TABLE settings ADD COLUMN supabase_id TEXT',
        );
        await customStatement(
          'ALTER TABLE settings ADD COLUMN last_modified INTEGER NOT NULL DEFAULT (strftime("%s", "now"))',
        );
        await customStatement(
          'ALTER TABLE settings ADD COLUMN needs_sync INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE settings ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE settings ADD COLUMN version INTEGER NOT NULL DEFAULT 1',
        );
      }

      if (from < 25) {
        // Create new table without unique constraint - include ALL columns
        await customStatement('''
          CREATE TABLE task_new (
            id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            project_id INTEGER NOT NULL REFERENCES project(id) ON DELETE CASCADE,
            unit TEXT,
            start_point INTEGER DEFAULT 0,
            current INTEGER NOT NULL DEFAULT 0,
            end_goal INTEGER NOT NULL DEFAULT 1,
            deadline INTEGER,
            is_completed INTEGER NOT NULL DEFAULT 0,
            completed_at INTEGER,
            parent_task_id INTEGER REFERENCES task_new(id) ON DELETE CASCADE,
            order_index INTEGER NOT NULL DEFAULT 0,
            depth INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Copy data from old table to new table
        await customStatement('''
          INSERT INTO task_new (
            id, name, project_id, unit, start_point, current, end_goal, 
            deadline, is_completed, completed_at, parent_task_id, order_index, depth
          )
          SELECT 
            id, name, project_id, unit, start_point, current, end_goal, 
            deadline, is_completed, completed_at, parent_task_id, order_index, depth
          FROM task
        ''');

        // Drop the old table
        await m.deleteTable('task');

        // Rename new table to original name
        await customStatement('ALTER TABLE task_new RENAME TO task');

        // Recreate the index
        await customStatement(
          'CREATE INDEX idx_task_project_id ON task(project_id)',
        );
      }
      if (from < 24) {
        await m.addColumn(project, project.color);
      }
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
