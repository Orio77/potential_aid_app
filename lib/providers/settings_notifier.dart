import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class AppSettings {
  final int defaultStartTime;
  final int defaultTaskLength;
  final int defaultBreakTime;
  final int? defaultTimelineProjectId;
  final int? defaultTimelineCategoryId;
  final bool defaultTimelineShowProjects;
  final bool defaultTimelineUncompletedOnly;

  AppSettings({
    required this.defaultStartTime,
    required this.defaultTaskLength,
    required this.defaultBreakTime,
    this.defaultTimelineProjectId,
    this.defaultTimelineCategoryId,
    this.defaultTimelineShowProjects = true,
    this.defaultTimelineUncompletedOnly = true,
  });

  bool get hasTimelineCustomization =>
      defaultTimelineProjectId != null ||
      defaultTimelineCategoryId != null ||
      !defaultTimelineShowProjects ||
      !defaultTimelineUncompletedOnly;

  AppSettings copyWith({
    int? defaultStartTime,
    int? defaultTaskLength,
    int? defaultBreakTime,
    int? defaultTimelineProjectId,
    int? defaultTimelineCategoryId,
    bool? defaultTimelineShowProjects,
    bool? defaultTimelineUncompletedOnly,
  }) {
    return AppSettings(
      defaultStartTime: defaultStartTime ?? this.defaultStartTime,
      defaultTaskLength: defaultTaskLength ?? this.defaultTaskLength,
      defaultBreakTime: defaultBreakTime ?? this.defaultBreakTime,
      defaultTimelineProjectId:
          defaultTimelineProjectId ?? this.defaultTimelineProjectId,
      defaultTimelineCategoryId:
          defaultTimelineCategoryId ?? this.defaultTimelineCategoryId,
      defaultTimelineShowProjects:
          defaultTimelineShowProjects ?? this.defaultTimelineShowProjects,
      defaultTimelineUncompletedOnly:
          defaultTimelineUncompletedOnly ?? this.defaultTimelineUncompletedOnly,
    );
  }
}

/// Resolved timeline UI state after validating stored IDs against the database.
class TimelineResolvedDefaults {
  final ProjectData? project;
  final ProjectCategoryData? category;
  final bool showProjects;
  final bool showOnlyUncompleted;

  const TimelineResolvedDefaults({
    required this.project,
    required this.category,
    required this.showProjects,
    required this.showOnlyUncompleted,
  });
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  final AppDatabase _database;

  SettingsNotifier(this._database)
    : super(
        AppSettings(
          defaultStartTime: 515,
          defaultTaskLength: 60,
          defaultBreakTime: 5,
        ),
      ) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final query = _database.select(_database.settings);
    final settingsList = await query.get();

    if (!mounted) return;

    if (settingsList.isNotEmpty) {
      final dbSettings = settingsList.first;
      state = _appSettingsFromRow(dbSettings);
    } else {
      await _saveCurrentSettings();
    }
  }

  AppSettings _appSettingsFromRow(Setting row) {
    return AppSettings(
      defaultStartTime: row.defaultStartTime,
      defaultTaskLength: row.defaultTaskLength,
      defaultBreakTime: row.defaultBreakTime,
      defaultTimelineProjectId: row.defaultTimelineProjectId,
      defaultTimelineCategoryId: row.defaultTimelineCategoryId,
      defaultTimelineShowProjects: row.defaultTimelineShowProjects ?? true,
      defaultTimelineUncompletedOnly: row.defaultTimelineUncompletedOnly ?? true,
    );
  }

  /// Validates stored project/category IDs; clears invalid rows in the database.
  Future<TimelineResolvedDefaults> resolveTimelineDefaults() async {
    final row =
        await (_database.select(_database.settings)
              ..where((s) => s.id.equals(1))
              ..limit(1))
            .getSingleOrNull();

    if (row == null) {
      return const TimelineResolvedDefaults(
        project: null,
        category: null,
        showProjects: true,
        showOnlyUncompleted: true,
      );
    }

    int? pid = row.defaultTimelineProjectId;
    int? cid = row.defaultTimelineCategoryId;
    final showProj = row.defaultTimelineShowProjects ?? true;
    final uncompleted = row.defaultTimelineUncompletedOnly ?? true;

    ProjectData? project;
    ProjectCategoryData? category;
    var needsDbWrite = false;

    if (pid != null) {
      final p = await _database.projectDao.getProjectById(pid);
      if (p == null || p.isDeleted) {
        pid = null;
        cid = null;
        needsDbWrite = true;
      } else {
        project = p;
        if (row.defaultTimelineCategoryId != null) {
          cid = null;
          needsDbWrite = true;
        }
      }
    } else if (cid != null) {
      final c = await _database.projectDao.getProjectCategoryByIdOrNull(cid);
      if (c == null) {
        cid = null;
        needsDbWrite = true;
      } else {
        category = c;
      }
    }

    if (needsDbWrite) {
      await (_database.update(_database.settings)..where((s) => s.id.equals(1)))
          .write(
            SettingsCompanion(
              defaultTimelineProjectId: Value(pid),
              defaultTimelineCategoryId: Value(cid),
              lastModified: Value(DateTime.now()),
            ),
          );
      if (mounted) {
        state = _appSettingsFromRow(
          row.copyWith(
            defaultTimelineProjectId: Value(pid),
            defaultTimelineCategoryId: Value(cid),
          ),
        );
      }
    } else if (mounted) {
      state = _appSettingsFromRow(row);
    }

    return TimelineResolvedDefaults(
      project: project,
      category: category,
      showProjects: showProj,
      showOnlyUncompleted: uncompleted,
    );
  }

  /// Persists either a default project **or** a default category (never both).
  Future<void> saveCurrentTimelineAsDefault({
    ProjectData? project,
    ProjectCategoryData? category,
    required bool showProjects,
    required bool showOnlyUncompleted,
  }) async {
    final int? pid = project?.id;
    final int? cid = project != null ? null : category?.id;

    state = AppSettings(
      defaultStartTime: state.defaultStartTime,
      defaultTaskLength: state.defaultTaskLength,
      defaultBreakTime: state.defaultBreakTime,
      defaultTimelineProjectId: pid,
      defaultTimelineCategoryId: cid,
      defaultTimelineShowProjects: showProjects,
      defaultTimelineUncompletedOnly: showOnlyUncompleted,
    );

    await _saveCurrentSettings();
  }

  Future<void> clearTimelineDefaults() async {
    state = AppSettings(
      defaultStartTime: state.defaultStartTime,
      defaultTaskLength: state.defaultTaskLength,
      defaultBreakTime: state.defaultBreakTime,
      defaultTimelineProjectId: null,
      defaultTimelineCategoryId: null,
      defaultTimelineShowProjects: true,
      defaultTimelineUncompletedOnly: true,
    );
    await _saveCurrentSettings();
  }

  Future<void> updateDefaultStartTime(int minutes) async {
    state = state.copyWith(defaultStartTime: minutes);
    await _saveCurrentSettings();
  }

  Future<void> updateDefaultTaskLength(int minutes) async {
    state = state.copyWith(defaultTaskLength: minutes);
    await _saveCurrentSettings();
  }

  Future<void> updateDefaultBreakTime(int minutes) async {
    state = state.copyWith(defaultBreakTime: minutes);
    await _saveCurrentSettings();
  }

  Future<void> _saveCurrentSettings() async {
    if (!mounted) return;

    final existing =
        await (_database.select(_database.settings)
              ..where((t) => t.id.equals(1))
              ..limit(1))
            .getSingleOrNull();

    final settings = SettingsCompanion.insert(
      id: const Value(1),
      defaultStartTime: state.defaultStartTime,
      defaultTaskLength: state.defaultTaskLength,
      defaultBreakTime: state.defaultBreakTime,
      defaultTimelineProjectId: Value(state.defaultTimelineProjectId),
      defaultTimelineCategoryId: Value(state.defaultTimelineCategoryId),
      defaultTimelineShowProjects: Value(state.defaultTimelineShowProjects),
      defaultTimelineUncompletedOnly: Value(state.defaultTimelineUncompletedOnly),
      pursuitStateJson: Value(existing?.pursuitStateJson),
      lastModified: DateTime.now(),
    );

    if (existing != null) {
      await (_database.update(_database.settings)..where((t) => t.id.equals(1)))
          .write(settings);
    } else {
      await _database.into(_database.settings).insert(settings);
    }
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
      final database = ref.watch(databaseProvider);
      return SettingsNotifier(database);
    });
