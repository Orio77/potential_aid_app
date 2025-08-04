import 'package:drift/drift.dart';
import 'package:potential_aid_app/models/project.dart';
import 'package:potential_aid_app/services/database.dart';

class Task extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get projectId => integer()
      .references(Project, #id, onDelete: KeyAction.cascade)
      .nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class TaskWithStats {
  final TaskData task;
  final int totalMinutesCompleted;
  final double completionPercentage;
  final int blocksCount;
  final int completedBlocksCount;

  TaskWithStats({
    required this.task,
    required this.totalMinutesCompleted,
    required this.completionPercentage,
    required this.blocksCount,
    required this.completedBlocksCount,
  });

  bool get hasTimeProgress => totalMinutesCompleted > 0;
  bool get isCompleteByTime => completionPercentage >= 100.0;
  bool get isCompleteByFlag => task.isCompleted;
  bool get isActuallyComplete => isCompleteByFlag || isCompleteByTime;

  String get statusDescription {
    if (isCompleteByFlag) return 'Completed';
    if (isCompleteByTime) return 'Time Complete';
    if (hasTimeProgress) return '${completionPercentage.round()}% done';
    return 'Not started';
  }
}

class TaskWithProject {
  final TaskData task;
  final ProjectData? project;

  TaskWithProject({required this.task, this.project});

  String get displayName => task.name;
  String get projectName => project?.name ?? 'No Project';
  bool get hasProject => project != null;
}
