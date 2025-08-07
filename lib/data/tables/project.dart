import 'package:drift/drift.dart';

class Project extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get deadline => dateTime()();
  IntColumn get startPoint => integer().withDefault(const Constant(0))();
  IntColumn get current => integer().withDefault(const Constant(0))();
  IntColumn get goal => integer().withDefault(const Constant(1))();
  TextColumn get unit => text().withDefault(const Constant(""))();
}
