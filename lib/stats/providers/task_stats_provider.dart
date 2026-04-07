import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:time_machine/time_machine.dart';

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

    final startOfMonth = LocalDate(
      monthYearDate.yearOfEra,
      monthYearDate.monthOfYear,
      1,
    );
    final endOfMonth = startOfMonth.addMonths(1).subtractDays(1);

    query.where(
      database.taskCompletion.completedAt.isBetweenValues(
        startOfMonth.toDateTimeUnspecified(),
        endOfMonth.toDateTimeUnspecified(),
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

/// [C] Tasks actually completed (isCompleted=true) within a given month,
/// optionally filtered by project. Replaces raw task_completion event counts.
final completedTasksByMonthProvider =
    FutureProvider.family<List<TaskData>, TaskCompletionParams>((
      ref,
      params,
    ) async {
      final database = ref.watch(databaseProvider);
      final year = params.monthYearDate.yearOfEra;
      final month = params.monthYearDate.monthOfYear;
      final start = DateTime(year, month, 1);
      final end = month == 12
          ? DateTime(year + 1, 1, 1)
          : DateTime(year, month + 1, 1);

      final query = database.select(database.task)
        ..where(
          (t) =>
              t.isCompleted.equals(true) &
              t.isDeleted.equals(false) &
              t.completedAt.isBiggerOrEqualValue(start) &
              t.completedAt.isSmallerThanValue(end),
        );

      if (params.projectId != null) {
        query.where((t) => t.projectId.equals(params.projectId!));
      }

      return query.get();
    });

/// [A] Number of consecutive days (going back from today) where at least one
/// block was completed or a task was finished.
final currentStreakProvider = FutureProvider<int>((ref) async {
  final database = ref.watch(databaseProvider);

  final dates = <DateTime>{};

  final blockCompletions = await database.select(database.blockCompletion).get();
  for (final bc in blockCompletions) {
    final dt = bc.completedAt;
    dates.add(DateTime(dt.year, dt.month, dt.day));
  }

  final completedTasks = await (database.select(database.task)
        ..where((t) => t.isCompleted.equals(true) & t.isDeleted.equals(false)))
      .get();
  for (final t in completedTasks) {
    if (t.completedAt != null) {
      final dt = t.completedAt!;
      dates.add(DateTime(dt.year, dt.month, dt.day));
    }
  }

  final now = DateTime.now();
  var checkDate = DateTime(now.year, now.month, now.day);
  var streak = 0;
  while (dates.contains(checkDate)) {
    streak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
  }
  return streak;
});
