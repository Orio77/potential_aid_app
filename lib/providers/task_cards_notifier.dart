import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:time_machine/time_machine.dart';

class TaskCardsNotifier extends StateNotifier<Map<LocalDate, List<TaskData>>> {
  final AppDatabase _database;

  TaskCardsNotifier(this._database) : super({});

  Future<void> loadTasksForMonth(LocalDate monthDate, {int depth = 0}) async {
    final monthStart = LocalDate(monthDate.yearOfEra, monthDate.monthOfYear, 1);
    final monthEnd = monthStart.addMonths(1).subtractDays(1);

    final tasks = await _database.taskDao.getAllTasks([
      (task) => task.depth.equals(depth),
      (task) => task.deadline.isNotNull(),
      (task) => task.deadline.isBetweenValues(
        monthStart.toDateTimeUnspecified(),
        monthEnd.toDateTimeUnspecified().add(Duration(hours: 23, minutes: 59)),
      ),
      (task) => task.isCompleted.equals(false),
    ]);

    final tasksByDate = <LocalDate, List<TaskData>>{};
    for (final task in tasks) {
      if (task.deadline == null) continue;
      final deadlineDate = LocalDate.dateTime(task.deadline!);
      tasksByDate.putIfAbsent(deadlineDate, () => []).add(task);
    }

    state = tasksByDate;
  }
}

final taskCardsNotifierProvider =
    StateNotifierProvider<TaskCardsNotifier, Map<LocalDate, List<TaskData>>>((
      ref,
    ) {
      final database = ref.watch(databaseProvider);
      return TaskCardsNotifier(database);
    });
