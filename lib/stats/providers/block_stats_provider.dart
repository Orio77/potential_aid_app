import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:time_machine/time_machine.dart';

// ── Data classes ─────────────────────────────────────────────────────────────

class WeekSummary {
  final int completedMinutes;
  final int plannedMinutes;
  const WeekSummary({
    required this.completedMinutes,
    required this.plannedMinutes,
  });
}

class ProjectTimeStat {
  final int projectId;
  final String projectName;
  final int minutes;
  const ProjectTimeStat({
    required this.projectId,
    required this.projectName,
    required this.minutes,
  });
}

class ProjectTaskStat {
  final int projectId;
  final String projectName;
  final int taskCount;
  const ProjectTaskStat({
    required this.projectId,
    required this.projectName,
    required this.taskCount,
  });
}

class DayBreakdown {
  final int day;
  final int minutes;
  final int tasksCompleted;
  const DayBreakdown({
    required this.day,
    required this.minutes,
    required this.tasksCompleted,
  });
}

class MonthDetail {
  /// Block-completion minutes for the month.
  final int totalMinutes;

  /// Block minutes that were planned (scheduled blocks) for the month.
  final int plannedMinutes;

  /// Number of distinct calendar days with any activity.
  final int activeDays;

  /// Max minutes in a single block_completion row for the month (longest session).
  final int longestSessionMinutes;

  /// Time spent per project, sorted descending.
  final List<ProjectTimeStat> timePerProject;

  /// Tasks completed per project, sorted descending.
  final List<ProjectTaskStat> tasksPerProject;

  /// Per-day breakdown (only days with activity).
  final List<DayBreakdown> dailyBreakdown;

  const MonthDetail({
    required this.totalMinutes,
    required this.plannedMinutes,
    required this.activeDays,
    required this.longestSessionMinutes,
    required this.timePerProject,
    required this.tasksPerProject,
    required this.dailyBreakdown,
  });

  double get completionRate =>
      plannedMinutes > 0 ? (totalMinutes / plannedMinutes).clamp(0.0, 1.0) : 0.0;

  int get avgMinutesPerActiveDay =>
      activeDays > 0 ? totalMinutes ~/ activeDays : 0;
}

// ── Query helpers ─────────────────────────────────────────────────────────────

Future<List<BlockCompletionData>> getBlockCompletions(
  AppDatabase database,
  LocalDate monthYearDate,
) async {
  final query = database.select(database.blockCompletion);

  query.where(
    (table) => table.completedAt.isBetweenValues(
      DateTime(monthYearDate.yearOfEra, monthYearDate.monthOfYear, 1),
      DateTime(
        monthYearDate.yearOfEra,
        monthYearDate.monthOfYear + 1,
        1,
      ).subtract(Duration(days: 1)),
    ),
  );

  query.orderBy([(bc) => OrderingTerm.asc(bc.completedAt)]);

  return await query.get();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final blockCompletionMonthlyNotifier =
    FutureProvider.family<List<BlockCompletionData>, LocalDate>((
      ref,
      date,
    ) async {
      final database = ref.watch(databaseProvider);
      return await getBlockCompletions(database, date);
    });

/// [B] Total planned vs completed block minutes for the current Mon–Sun week.
final weekSummaryProvider = FutureProvider<WeekSummary>((ref) async {
  final database = ref.watch(databaseProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 7));

  final completionQuery = database.selectOnly(database.blockCompletion)
    ..addColumns([database.blockCompletion.count.sum()])
    ..where(
      database.blockCompletion.completedAt.isBiggerOrEqualValue(startOfWeek),
    )
    ..where(
      database.blockCompletion.completedAt.isSmallerThanValue(endOfWeek),
    );
  final completionResult = await completionQuery.getSingle();
  final completedMinutes =
      completionResult.read(database.blockCompletion.count.sum()) ?? 0;

  final plannedQuery = database.selectOnly(database.block)
    ..addColumns([database.block.lengthMinutes.sum()])
    ..where(database.block.dayLocal.isBiggerOrEqualValue(startOfWeek))
    ..where(database.block.dayLocal.isSmallerThanValue(endOfWeek))
    ..where(database.block.isDeleted.equals(false));
  final plannedResult = await plannedQuery.getSingle();
  final plannedMinutes =
      plannedResult.read(database.block.lengthMinutes.sum()) ?? 0;

  return WeekSummary(
    completedMinutes: completedMinutes,
    plannedMinutes: plannedMinutes,
  );
});

final monthDetailProvider =
    FutureProvider.family<MonthDetail, LocalDate>((ref, monthYearDate) async {
  final db = ref.watch(databaseProvider);
  final year = monthYearDate.yearOfEra;
  final month = monthYearDate.monthOfYear;
  final start = DateTime(year, month, 1);
  final end = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);

  // ── Block completions for the month ──────────────────────────────────────
  final blockRows = await (db.select(db.blockCompletion).join([
    innerJoin(db.block, db.blockCompletion.blockId.equalsExp(db.block.id)),
    innerJoin(db.project, db.block.projectId.equalsExp(db.project.id)),
  ])
        ..addColumns([
          db.blockCompletion.count,
          db.blockCompletion.completedAt,
          db.block.projectId,
          db.project.name,
        ])
        ..where(db.blockCompletion.completedAt.isBiggerOrEqualValue(start))
        ..where(db.blockCompletion.completedAt.isSmallerThanValue(end)))
      .get();

  int totalMinutes = 0;
  int longestSession = 0;
  final Map<int, int> minutesByProject = {};
  final Map<String, String> projectNames = {};
  final Map<int, int> minutesByDay = {};

  for (final row in blockRows) {
    final minutes = row.read(db.blockCompletion.count) ?? 0;
    final projectId = row.read(db.block.projectId)!;
    final projectName = row.read(db.project.name) ?? '';
    final completedAt = row.read(db.blockCompletion.completedAt)!;

    totalMinutes += minutes;
    longestSession = max(longestSession, minutes);
    minutesByProject[projectId] = (minutesByProject[projectId] ?? 0) + minutes;
    projectNames[projectId.toString()] = projectName;
    minutesByDay[completedAt.day] = (minutesByDay[completedAt.day] ?? 0) + minutes;
  }

  // ── Planned minutes for the month ─────────────────────────────────────────
  final plannedResult = await (db.selectOnly(db.block)
        ..addColumns([db.block.lengthMinutes.sum()])
        ..where(db.block.dayLocal.isBiggerOrEqualValue(start))
        ..where(db.block.dayLocal.isSmallerThanValue(end))
        ..where(db.block.isDeleted.equals(false)))
      .getSingle();
  final plannedMinutes = plannedResult.read(db.block.lengthMinutes.sum()) ?? 0;

  // ── Completed tasks for the month ─────────────────────────────────────────
  final taskRows = await (db.select(db.task).join([
    innerJoin(db.project, db.task.projectId.equalsExp(db.project.id)),
  ])
        ..addColumns([db.task.projectId, db.project.name, db.task.completedAt])
        ..where(db.task.isCompleted.equals(true))
        ..where(db.task.isDeleted.equals(false))
        ..where(db.task.completedAt.isBiggerOrEqualValue(start))
        ..where(db.task.completedAt.isSmallerThanValue(end)))
      .get();

  final Map<int, int> tasksByProject = {};
  final Map<int, int> tasksByDay = {};

  for (final row in taskRows) {
    final projectId = row.read(db.task.projectId)!;
    final projectName = row.read(db.project.name) ?? '';
    final completedAt = row.read(db.task.completedAt);

    tasksByProject[projectId] = (tasksByProject[projectId] ?? 0) + 1;
    projectNames[projectId.toString()] = projectName;
    if (completedAt != null) {
      tasksByDay[completedAt.day] = (tasksByDay[completedAt.day] ?? 0) + 1;
    }
  }

  // ── Active days ────────────────────────────────────────────────────────────
  final activeDaySet = <int>{...minutesByDay.keys, ...tasksByDay.keys};

  // ── Build sorted lists ────────────────────────────────────────────────────
  final timePerProject = minutesByProject.entries
      .map((e) => ProjectTimeStat(
            projectId: e.key,
            projectName: projectNames[e.key.toString()] ?? '',
            minutes: e.value,
          ))
      .toList()
    ..sort((a, b) => b.minutes.compareTo(a.minutes));

  final tasksPerProject = tasksByProject.entries
      .map((e) => ProjectTaskStat(
            projectId: e.key,
            projectName: projectNames[e.key.toString()] ?? '',
            taskCount: e.value,
          ))
      .toList()
    ..sort((a, b) => b.taskCount.compareTo(a.taskCount));

  // ── Daily breakdown (all days with any activity) ──────────────────────────
  final allDays = <int>{...minutesByDay.keys, ...tasksByDay.keys};
  final dailyBreakdown = allDays
      .map((day) => DayBreakdown(
            day: day,
            minutes: minutesByDay[day] ?? 0,
            tasksCompleted: tasksByDay[day] ?? 0,
          ))
      .toList()
    ..sort((a, b) => a.day.compareTo(b.day));

  return MonthDetail(
    totalMinutes: totalMinutes,
    plannedMinutes: plannedMinutes,
    activeDays: activeDaySet.length,
    longestSessionMinutes: longestSession,
    timePerProject: timePerProject,
    tasksPerProject: tasksPerProject,
    dailyBreakdown: dailyBreakdown,
  );
});

/// [F] Total block-completion minutes grouped by day of week (index 0=Mon, 6=Sun)
/// over the last 90 days.
final dayOfWeekStatsProvider = FutureProvider<List<int>>((ref) async {
  final database = ref.watch(databaseProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 90));

  final completions = await (database.select(database.blockCompletion)
        ..where((bc) => bc.completedAt.isBiggerOrEqualValue(cutoff)))
      .get();

  final byDay = List.filled(7, 0);
  for (final c in completions) {
    final dow = c.completedAt.weekday - 1; // 0=Mon, 6=Sun
    byDay[dow] += c.count;
  }
  return byDay;
});
