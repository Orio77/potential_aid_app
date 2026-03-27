import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:time_machine/time_machine.dart';

class TaskCardsNotifier extends StateNotifier<Map<LocalDate, List<TaskData>>> {
  final AppDatabase _database;
  final int depth;

  TaskCardsNotifier(this._database, this.depth) : super({});

  Future<void> loadTasksForMonth({
    required LocalDate monthDate,
    required int depth,
    int? categoryId,
    int? projectId,
    bool showOnlyUncompleted = true,
  }) async {
    final monthStart = LocalDate(monthDate.yearOfEra, monthDate.monthOfYear, 1);
    final monthEnd = monthStart.addMonths(1).subtractDays(1);

    final tasks = await _database.taskDao.getAllTasks([
      (task) => task.depth.equals(depth),
      (task) => task.deadline.isNotNull(),
      if (projectId != null) (task) => task.projectId.equals(projectId),
      (task) => task.deadline.isBetweenValues(
        monthStart.toDateTimeUnspecified(),
        monthEnd.toDateTimeUnspecified().add(Duration(hours: 23, minutes: 59)),
      ),
      if (showOnlyUncompleted) (task) => task.isCompleted.equals(false),
    ]);

    if (categoryId != null) {
      final projects = await _database.projectDao.getProjectsByCategory(
        categoryId,
      );
      final projectIds = projects.map((p) => p.id).toSet();
      tasks.retainWhere((task) => projectIds.contains(task.projectId));
    }

    final tasksByDate = <LocalDate, List<TaskData>>{};
    for (final task in tasks) {
      if (task.deadline == null) continue;
      final deadlineDate = LocalDate.dateTime(task.deadline!);
      tasksByDate.putIfAbsent(deadlineDate, () => []).add(task);
    }

    if (mounted) {
      state = tasksByDate;
    }
  }
}

final taskCardsNotifierProvider =
    StateNotifierProvider.family<
      TaskCardsNotifier,
      Map<LocalDate, List<TaskData>>,
      int
    >((ref, depth) {
      final database = ref.watch(databaseProvider);
      return TaskCardsNotifier(database, depth);
    });
