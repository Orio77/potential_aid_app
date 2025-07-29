import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/services/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

class AppSettings {
  final int defaultStartTime;
  final int defaultTaskLength;
  final int defaultBreakTime;

  AppSettings({
    required this.defaultStartTime,
    required this.defaultTaskLength,
    required this.defaultBreakTime,
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

    if (settingsList.isNotEmpty) {
      final dbSettings = settingsList.first;
      state = AppSettings(
        defaultStartTime: dbSettings.defaultStartTime,
        defaultTaskLength: dbSettings.defaultTaskLength,
        defaultBreakTime: dbSettings.defaultBreakTime,
      );
    } else {
      await _saveCurrentSettings();
    }
  }

  Future<void> updateDefaultStartTime(int minutes) async {
    state = AppSettings(
      defaultStartTime: minutes,
      defaultTaskLength: state.defaultTaskLength,
      defaultBreakTime: state.defaultBreakTime,
    );

    _saveCurrentSettings();
  }

  Future<void> updateDefaultTaskLength(int minutes) async {
    state = AppSettings(
      defaultStartTime: state.defaultStartTime,
      defaultTaskLength: minutes,
      defaultBreakTime: state.defaultBreakTime,
    );

    _saveCurrentSettings();
  }

  Future<void> updateDefaultBreakTime(int minutes) async {
    state = AppSettings(
      defaultStartTime: state.defaultStartTime,
      defaultTaskLength: state.defaultTaskLength,
      defaultBreakTime: minutes,
    );

    _saveCurrentSettings();
  }

  Future<void> _saveCurrentSettings() async {
    final settings = SettingsCompanion.insert(
      id: 1,
      defaultStartTime: state.defaultStartTime,
      defaultTaskLength: state.defaultTaskLength,
      defaultBreakTime: state.defaultBreakTime,
    );

    await _database.into(_database.settings).insertOnConflictUpdate(settings);
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
      final database = ref.watch(databaseProvider);
      return SettingsNotifier(database);
    });
