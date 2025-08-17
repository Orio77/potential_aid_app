import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/task.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Task])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.attachedDatabase);

  Future<List<TaskData>> searchTasks({
    required String query,
    int? limit,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final selectQuery = select(task)
      ..where((t) => t.name.lower().like('${q.toLowerCase()}%'));

    if (limit != null) {
      selectQuery.limit(limit);
    }

    return selectQuery.get();
  }
}
