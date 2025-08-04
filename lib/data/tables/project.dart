import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';

class Project extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get deadline => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

class ProjectWithStats {
  final ProjectData project;
  final int taskCount;
  final double completionPercentage;
  final int daysUntilDeadline;

  ProjectWithStats({
    required this.project,
    required this.taskCount,
    required this.completionPercentage,
    required this.daysUntilDeadline,
  });
}
