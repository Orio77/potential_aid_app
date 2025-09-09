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

class TaskCompletionParams {
  final LocalDate monthYearDate;
  final int? projectId;

  const TaskCompletionParams({required this.monthYearDate, this.projectId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCompletionParams &&
          runtimeType == other.runtimeType &&
          monthYearDate == other.monthYearDate &&
          projectId == other.projectId;

  @override
  int get hashCode => monthYearDate.hashCode ^ projectId.hashCode;
}

Future<int> calculateTimeSpentTotal(AppDatabase database, int projectId) async {
  return await _getBlockCompletionSum(database, projectId);
}

Future<double> calculateAverageUnitPerDay(
  AppDatabase database,
  int projectId,
) async {
  // get projects unit
  final query = database.selectOnly(database.project)
    ..addColumns([database.project.unit])
    ..where(database.project.id.equals(projectId));

  final result = await query.getSingle();
  final unit = result.read(database.project.unit);

  // get tasks with the same unit from last week
  final weekBefore = LocalDate.today().subtractDays(7).toDateTimeUnspecified();
  final tasks =
      await (database.select(database.taskCompletion).join([
              innerJoin(
                database.task,
                database.task.id.equalsExp(database.taskCompletion.taskId),
              ),
            ])
            ..addColumns([database.taskCompletion.count])
            ..where(
              unit != null ? database.task.unit.equals(unit) : Constant(false),
            )
            ..where(
              database.taskCompletion.completedAt.isBiggerThanValue(weekBefore),
            ))
          .get();

  // calculate average count per day
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

Future<List<TaskCompletionData>> getTaskCompletions(
  AppDatabase database,
  LocalDate monthYearDate, [
  int? projectId,
]) async {
  if (projectId != null) {
    final query = database.select(database.taskCompletion).join([
      innerJoin(
        database.task,
        database.taskCompletion.taskId.equalsExp(database.task.id),
      ),
    ]);

    query.where(database.task.projectId.equals(projectId));

    query.where(
      database.taskCompletion.completedAt.isBetweenValues(
        DateTime(monthYearDate.yearOfEra, monthYearDate.monthOfYear, 1),
        DateTime(
          monthYearDate.yearOfEra,
          monthYearDate.monthOfYear + 1,
          1,
        ).subtract(Duration(days: 1)),
      ),
    );

    query.orderBy([OrderingTerm.asc(database.taskCompletion.completedAt)]);

    final rows = await query.get();
    return rows.map((row) => row.readTable(database.taskCompletion)).toList();
  } else {
    final query = database.select(database.taskCompletion);

    query.where(
      (tc) => tc.completedAt.isBetweenValues(
        DateTime(monthYearDate.yearOfEra, monthYearDate.monthOfYear, 1),
        DateTime(
          monthYearDate.yearOfEra,
          monthYearDate.monthOfYear + 1,
          1,
        ).subtract(Duration(days: 1)),
      ),
    );

    query.orderBy([(tc) => OrderingTerm.asc(tc.completedAt)]);

    return await query.get();
  }
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

final taskCompletionMonthlyNotifier =
    FutureProvider.family<List<TaskCompletionData>, TaskCompletionParams>((
      ref,
      params,
    ) async {
      final database = ref.watch(databaseProvider);

      return await getTaskCompletions(
        database,
        params.monthYearDate,
        params.projectId,
      );
    });
