import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/models/sync_models.dart';
import 'package:potential_aid_app/services/supabase_service.dart';
import 'package:potential_aid_app/services/sync_repository.dart';
import 'package:potential_aid_app/services/sync_operations.dart';
import 'package:potential_aid_app/services/sync_record_mapper.dart';

// Re-export models for backward compatibility
export 'package:potential_aid_app/models/sync_models.dart';

/// SyncService handles bidirectional synchronization between local Drift database and Supabase
///
/// Key Features:
/// - Initial migration from local-only data to remote
/// - Bidirectional sync with conflict resolution
/// - Offline support with sync queuing
/// - Status monitoring and progress tracking
class SyncService {
  final AppDatabase _database;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final void Function()? onSyncComplete;

  // Extracted components
  late final SyncRepository _repository;
  late final SyncRecordMapper _recordMapper;
  late final SyncOperations _operations;

  // State management
  SyncStatus _currentStatus = SyncStatus.idle;
  DateTime? _lastSyncTime;
  SyncResult? _lastSyncResult;
  Timer? _statusDebounceTimer;

  // Stream controllers for real-time status updates
  late final StreamController<SyncStatus> _statusController;
  late final StreamController<SyncResult?> _resultController;

  // Public getters
  SyncStatus get currentStatus => _currentStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncResult? get lastSyncResult => _lastSyncResult;
  AppDatabase get database => _database;

  // Stream getters for real-time updates
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<SyncResult?> get resultStream => _resultController.stream;

  SyncService(this._database, {this.onSyncComplete}) {
    // Initialize extracted components
    _repository = SyncRepository(_database);
    _recordMapper = SyncRecordMapper(_repository, _supabaseService);
    _operations = SyncOperations(_repository, _supabaseService, _recordMapper);

    // Initialize stream controllers
    _statusController = StreamController<SyncStatus>.broadcast();
    _resultController = StreamController<SyncResult?>.broadcast();

    // Add initial values to streams
    Future.microtask(() {
      if (!_statusController.isClosed) {
        _statusController.add(_currentStatus);
      }
      if (!_resultController.isClosed) {
        _resultController.add(_lastSyncResult);
      }
    });
  }

  /// Dispose method to clean up stream controllers
  void dispose() {
    _statusDebounceTimer?.cancel();
    _statusController.close();
    _resultController.close();
  }

  /// Key used to ensure the one-shot legacy-data repair runs exactly once
  /// after upgrading to the code that fixes the version / cascade bugs.
  static const String _repairFlagKey = 'legacy_repair_v1_done';

  /// Initialize sync service - must be called before using
  Future<void> initialize() async {
    try {
      await _supabaseService.initialize();
      try {
        await _supabaseService.signInWithSharedAccount();
      } catch (e) {
        await _supabaseService.signInAnonymously();
      }
    } catch (e) {
      _updateStatus(SyncStatus.offline);
    }
    _lastSyncTime = await _loadLastSyncTime();

    // Run the one-shot legacy repair pass on first launch after this fix.
    // Safe to call in the background; it only touches rows the current code
    // would touch anyway (orphans under soft-deleted projects).
    unawaited(_maybeRunLegacyRepair());
  }

  Future<void> _maybeRunLegacyRepair() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_repairFlagKey) == true) return;
      await repairOrphanedRecords();
      await prefs.setBool(_repairFlagKey, true);
    } catch (_) {
      // If it fails, we leave the flag unset so it can retry on next launch.
    }
  }

  /// Walks every soft-deleted project and cascades the soft-delete to its
  /// still-live children (tasks, blocks, block_tasks, completions) so they
  /// get pushed as deletes to Supabase on the next sync. Also repairs rows
  /// whose `needs_sync` flag was lost due to the previous version-overwrite
  /// bug.
  ///
  /// This is idempotent: running it twice is a no-op.
  Future<int> repairOrphanedRecords() async {
    int healed = 0;

    final deletedProjects = await (_database.select(_database.project)
          ..where((p) => p.isDeleted.equals(true)))
        .get();

    for (final p in deletedProjects) {
      // These two helpers skip already-deleted rows internally, so the pass
      // is safe to re-run.
      await _database.taskDao.softDeleteTasksByProject(p.id);
      await _database.blockDao.softDeleteBlocksByProject(p.id);
      healed++;
    }

    // #region agent log
    try {
      final f = File('debug-9f5051.log');
      final entry = {
        'sessionId': '9f5051',
        'hypothesisId': 'repair',
        'location': 'sync_service.dart:repairOrphanedRecords',
        'message': 'legacy_repair_done',
        'data': {
          'deletedProjectsScanned': deletedProjects.length,
          'healed': healed,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      f.writeAsStringSync('${jsonEncode(entry)}\n',
          mode: FileMode.append, flush: false);
    } catch (_) {}
    // #endregion

    return healed;
  }

  /// Re-queues every still-live local row for push on the next sync. Useful
  /// if the caller wants to force reconciliation after a destructive manual
  /// edit to Supabase.
  Future<void> markEverythingForResync() async {
    final now = Value(DateTime.now());

    await _database.batch((batch) {
      batch.update(
        _database.project,
        ProjectCompanion(needsSync: const Value(true), lastModified: now),
        where: (p) => p.isDeleted.equals(false),
      );
      batch.update(
        _database.projectCategory,
        ProjectCategoryCompanion(
          needsSync: const Value(true),
          lastModified: now,
        ),
        where: (pc) => pc.isDeleted.equals(false),
      );
      batch.update(
        _database.task,
        TaskCompanion(needsSync: const Value(true), lastModified: now),
        where: (t) => t.isDeleted.equals(false),
      );
      batch.update(
        _database.block,
        BlockCompanion(needsSync: const Value(true), lastModified: now),
        where: (b) => b.isDeleted.equals(false),
      );
      batch.update(
        _database.blockTask,
        BlockTaskCompanion(needsSync: const Value(true), lastModified: now),
        where: (bt) => bt.isDeleted.equals(false),
      );
      batch.update(
        _database.taskCompletion,
        TaskCompletionCompanion(
          needsSync: const Value(true),
          lastModified: now,
        ),
        where: (tc) => tc.isDeleted.equals(false),
      );
      batch.update(
        _database.blockCompletion,
        BlockCompletionCompanion(
          needsSync: const Value(true),
          lastModified: now,
        ),
        where: (bc) => bc.isDeleted.equals(false),
      );
      batch.update(
        _database.settings,
        SettingsCompanion(needsSync: const Value(true), lastModified: now),
      );
    });
  }

  /// Main sync method - handles the complete sync process
  Future<SyncResult> sync({
    SyncDirection direction = SyncDirection.bidirectional,
  }) async {
    if (_currentStatus == SyncStatus.syncing) {
      return SyncResult(
        success: false,
        error: 'Sync already in progress',
        timestamp: DateTime.now(),
      );
    }

    _updateStatus(SyncStatus.syncing);
    _repository.resetCaches();

    try {
      // Check connectivity
      if (!await _supabaseService.hasInternetConnection()) {
        _updateStatus(SyncStatus.offline);
        return SyncResult(
          success: false,
          error: 'No internet connection',
          timestamp: DateTime.now(),
        );
      }

      int totalRecordsSynced = 0;
      Map<String, int> tableStats = {};

      // Determine if this is first sync (initial migration scenario)
      final isFirstSync = _lastSyncTime == null;
      if (isFirstSync) {
        final migrationResult = await _operations.performInitialMigration();
        totalRecordsSynced += migrationResult.recordsSynced;
        tableStats.addAll(migrationResult.tableStats);
      }

      // Perform bidirectional sync
      if (direction == SyncDirection.push ||
          direction == SyncDirection.bidirectional) {
        final pushResult = await _operations.pushLocalChanges();
        totalRecordsSynced += pushResult.recordsSynced;
        _mergeTableStats(tableStats, pushResult.tableStats);
      }

      if (direction == SyncDirection.pull ||
          direction == SyncDirection.bidirectional) {
        final pullResult = await _operations.pullRemoteChanges(_lastSyncTime);
        totalRecordsSynced += pullResult.recordsSynced;
        _mergeTableStats(tableStats, pullResult.tableStats);
      }

      // Save sync timestamp
      final now = DateTime.now().toUtc();
      await _saveLastSyncTime(now);
      _lastSyncTime = now;

      final result = SyncResult(
        success: true,
        recordsSynced: totalRecordsSynced,
        tableStats: tableStats,
        timestamp: now,
      );

      _updateSyncResult(result);
      _updateStatus(SyncStatus.success);

      // Trigger callback to invalidate providers
      _notifyProviderInvalidation();

      return result;
    } catch (e) {
      final result = SyncResult(
        success: false,
        error: e.toString(),
        timestamp: DateTime.now(),
      );

      _updateSyncResult(result);
      _updateStatus(SyncStatus.error);

      return result;
    }
  }

  /// Get count of records needing sync across all tables
  Future<int> getPendingSyncCount() async {
    int count = 0;
    for (final tableName in SyncOperations.tableMapping.keys) {
      final records = await _repository.getRecordsNeedingSync(tableName);
      count += records.length;
    }
    return count;
  }

  /// Check if sync is needed (has pending changes)
  Future<bool> needsSync() async {
    return (await getPendingSyncCount()) > 0;
  }

  /// Clear the stored last sync time
  Future<void> clearLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_time');
    _lastSyncTime = null;
  }

  // Private helper methods

  /// Trigger callback to invalidate providers after sync
  void _notifyProviderInvalidation() {
    if (onSyncComplete != null) {
      try {
        onSyncComplete!();
      } catch (e) {
        // Continue execution even if callback fails
      }
    }
  }

  /// Update sync status with debouncing
  void _updateStatus(SyncStatus status) {
    final oldStatus = _currentStatus;

    if (oldStatus != status) {
      _currentStatus = status;

      // Cancel any pending status update
      _statusDebounceTimer?.cancel();

      // For critical status changes (syncing), update immediately
      if (status == SyncStatus.syncing || status == SyncStatus.error) {
        _notifyStatusChange(status);
      } else {
        // Debounce other status changes by 100ms
        _statusDebounceTimer = Timer(const Duration(milliseconds: 100), () {
          _notifyStatusChange(status);
        });
      }
    }
  }

  /// Notify status change to stream listeners
  void _notifyStatusChange(SyncStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Update sync result and notify listeners
  void _updateSyncResult(SyncResult? result) {
    if (_lastSyncResult != result) {
      _lastSyncResult = result;
      if (!_resultController.isClosed) {
        _resultController.add(result);
      }
    }
  }

  /// Merge table statistics
  void _mergeTableStats(Map<String, int> target, Map<String, int> source) {
    for (final entry in source.entries) {
      target[entry.key] = (target[entry.key] ?? 0) + entry.value;
    }
  }

  /// Load last sync timestamp from local storage
  Future<DateTime?> _loadLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString('last_sync_time');

      if (timestampStr != null && timestampStr.isNotEmpty) {
        return DateTime.tryParse(timestampStr);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save last sync timestamp to local storage
  Future<void> _saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', time.toIso8601String());
  }
}
