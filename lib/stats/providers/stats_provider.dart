export 'package:potential_aid_app/stats/providers/task_stats_provider.dart';
export 'package:potential_aid_app/stats/providers/block_stats_provider.dart';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:time_machine/time_machine.dart';

class ProjectStats {
  final int timeSpentTotal;
  final double averageUnitPerDay;
  final double lifeDevoted;

  const ProjectStats({
    required this.timeSpentTotal,
    required this.averageUnitPerDay,
    required this.lifeDevoted,
  });
}

Future<int> calculateTimeSpentTotal(AppDatabase database, int projectId) async {
  return await _getBlockCompletionSum(database, projectId);
}

Future<double> calculateAverageUnitPerDay(
  AppDatabase database,
  int projectId,
) async {
  final query = database.selectOnly(database.project)
    ..addColumns([database.project.unit])
    ..where(database.project.id.equals(projectId));

  final result = await query.getSingle();
  final unit = result.read(database.project.unit);

  final weekBefore = LocalDate.today().subtractDays(7).toDateTimeUnspecified();
  final tasks =
      await (database.select(database.taskCompletion).join([
              innerJoin(
                database.task,
                database.task.id.equalsExp(database.taskCompletion.taskId),
              ),
            ])
            ..addColumns([database.taskCompletion.count])
            ..where(database.task.projectId.equals(projectId))
            ..where(
              unit != null ? database.task.unit.equals(unit) : Constant(false),
            )
            ..where(
              database.taskCompletion.completedAt.isBiggerThanValue(weekBefore),
            ))
          .get();

  final sum = tasks.fold<int>(
    0,
    (total, task) => total + (task.read(database.taskCompletion.count) ?? 0),
  );
  return ((sum / 7.0) * 100).round() / 100.0;
}

Future<double> calculateLifeDevoted(AppDatabase database, int projectId) async {
  final res = (await _getBlockCompletionSum(database, projectId, 7)) / 112;
  return (res * 100).round() / 100.0;
}

Future<int> _getBlockCompletionSum(
  AppDatabase database,
  int projectId, [
  int? lastDays,
]) async {
  final query = database.selectOnly(database.blockCompletion)
    ..addColumns([database.blockCompletion.count.sum()])
    ..join([
      innerJoin(
        database.block,
        database.blockCompletion.blockId.equalsExp(database.block.id),
      ),
    ])
    ..where(database.block.projectId.equals(projectId));

  if (lastDays != null) {
    final cutoffDate = LocalDate.today()
        .subtractDays(lastDays)
        .toDateTimeUnspecified();
    query.where(
      database.blockCompletion.completedAt.isBiggerThanValue(cutoffDate),
    );
  }

  final result = await query.getSingle();
  return result.read(database.blockCompletion.count.sum()) ?? 0;
}

final projectStatsNotifier = FutureProvider.family<ProjectStats, int>((
  ref,
  projectId,
) async {
  final database = ref.watch(databaseProvider);

  final results = await Future.wait([
    calculateTimeSpentTotal(database, projectId),
    calculateAverageUnitPerDay(database, projectId),
    calculateLifeDevoted(database, projectId),
  ]);

  return ProjectStats(
    timeSpentTotal: results[0] as int,
    averageUnitPerDay: results[1] as double,
    lifeDevoted: results[2] as double,
  );
});
