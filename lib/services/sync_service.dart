import 'dart:async';
import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/services/supabase_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncStatus { idle, syncing, success, error, offline }

enum SyncDirection {
  push, // Local -> Remote
  pull, // Remote -> Local
  bidirectional, // Both directions
}

class SyncResult {
  final bool success;
  final String? error;
  final int recordsSynced;
  final Map<String, int> tableStats;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    this.error,
    this.recordsSynced = 0,
    this.tableStats = const {},
    required this.timestamp,
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, error: $error, recordsSynced: $recordsSynced, tableStats: $tableStats, timestamp: $timestamp)';
  }
}

/// SyncService handles bidirectional synchronization between local Drift database and Supabase
///
/// Key Features:
/// - Initial migration from local-only data to remote
/// - Bidirectional sync with conflict resolution
/// - Offline support with sync queuing
/// - Status monitoring and progress tracking
class SyncService {
  SyncService(this._database, {this.onSyncComplete}) {
    // Initialize stream controllers
    _statusController = StreamController<SyncStatus>.broadcast();
    _resultController = StreamController<SyncResult?>.broadcast();

    // Add initial values to streams to prevent hanging listeners
    Future.microtask(() {
      if (!_statusController.isClosed) {
        _statusController.add(_currentStatus);
      }
      if (!_resultController.isClosed) {
        _resultController.add(_lastSyncResult);
      }
    });
  }

  final AppDatabase _database;
  final SupabaseService _supabaseService = SupabaseService.instance;
  final Uuid _uuid =
      const Uuid(); // Will be used for generating UUIDs in migration
  final Map<String, Map<int, String?>> _localToSupabaseCache = {};
  final Map<String, Map<String, int>> _supabaseToLocalCache = {};
  final void Function()? onSyncComplete;

  SyncStatus _currentStatus = SyncStatus.idle;
  DateTime? _lastSyncTime;
  SyncResult? _lastSyncResult;
  Timer? _statusDebounceTimer;

  // Stream controllers for real-time status updates
  late final StreamController<SyncStatus> _statusController;
  late final StreamController<SyncResult?> _resultController;

  // Getters
  SyncStatus get currentStatus => _currentStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  SyncResult? get lastSyncResult => _lastSyncResult;
  AppDatabase get database => _database;

  // Stream getters for real-time updates
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<SyncResult?> get resultStream => _resultController.stream;

  /// Dispose method to clean up stream controllers
  void dispose() {
    _statusDebounceTimer?.cancel();
    _statusController.close();
    _resultController.close();
  }

  // Table mapping: local table name -> remote table name
  // Supabase tables mirror the local Drift schema, so keep names singular
  static const Map<String, String> _tableMapping = {
    'project_category': 'project_category',
    'project': 'project',
    'task': 'task',
    'block': 'block',
    'block_task': 'block_task',
    'task_completion': 'task_completion',
    'block_completion': 'block_completion',
    'settings': 'settings',
  };

  /// Initialize sync service - must be called before using
  Future<void> initialize() async {
    try {
      await _supabaseService.initialize();
      // Try shared user authentication first, fallback to anonymous
      try {
        await _supabaseService.signInWithSharedAccount();
      } catch (e) {
        await _supabaseService.signInAnonymously();
      }
    } catch (e) {
      // Continue without sync functionality if auth fails
      _updateStatus(SyncStatus.offline);
    }
    _lastSyncTime = await _loadLastSyncTime();
  }

  /// Main sync method - handles the complete sync process
  ///
  /// Handles three scenarios:
  /// 1. Initial migration: Local data exists, remote is empty
  /// 2. Incremental sync: Both local and remote have data
  /// 3. Fresh start: Both local and remote are empty
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
    _resetLookupCaches();

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
        final migrationResult = await _performInitialMigration();
        totalRecordsSynced += migrationResult.recordsSynced;
        tableStats.addAll(migrationResult.tableStats);
      }

      // Perform bidirectional sync
      if (direction == SyncDirection.push ||
          direction == SyncDirection.bidirectional) {
        final pushResult = await _pushLocalChanges();
        totalRecordsSynced += pushResult.recordsSynced;
        _mergeTableStats(tableStats, pushResult.tableStats);
      }

      if (direction == SyncDirection.pull ||
          direction == SyncDirection.bidirectional) {
        final pullResult = await _pullRemoteChanges();
        totalRecordsSynced += pullResult.recordsSynced;
        _mergeTableStats(tableStats, pullResult.tableStats);
      }

      // Save sync timestamp
      final now = DateTime.now();
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

      // Trigger callback to invalidate providers and refresh UI with new data
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

  void _resetLookupCaches() {
    _localToSupabaseCache.clear();
    _supabaseToLocalCache.clear();
  }

  /// Handle initial migration when local DB has existing data but remote is empty
  /// This is crucial for users who have been using the app offline
  Future<SyncResult> _performInitialMigration() async {
    int totalRecords = 0;
    Map<String, int> tableStats = {};

    try {
      // Migrate each table
      for (final entry in _tableMapping.entries) {
        final localTable = entry.key;
        final remoteTable = entry.value;

        final recordsToMigrate = await _getAllRecords(localTable);

        if (recordsToMigrate.isNotEmpty) {
          // Convert local records to remote format
          final remoteRecords = <Map<String, dynamic>>[];
          for (final record in recordsToMigrate) {
            final supabaseId = await _ensureSupabaseIdValue(localTable, record);
            final remoteRecord = await _convertLocalToRemote(
              localTable,
              record,
              supabaseId,
            );
            remoteRecords.add(remoteRecord);
          }

          // Upload to Supabase
          final uploadedRecords = await _supabaseService.upsertRecords(
            remoteTable,
            remoteRecords,
          );

          // Update local records with supabase_id
          await _updateLocalWithRemoteIds(
            localTable,
            recordsToMigrate,
            uploadedRecords,
          );

          tableStats[localTable] = recordsToMigrate.length;
          totalRecords = totalRecords + recordsToMigrate.length;
        }
      }

      return SyncResult(
        success: true,
        recordsSynced: totalRecords,
        tableStats: tableStats,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Push local changes (where needs_sync = true) to remote
  Future<SyncResult> _pushLocalChanges() async {
    int totalRecords = 0;
    Map<String, int> tableStats = {};

    try {
      for (final entry in _tableMapping.entries) {
        final localTable = entry.key;
        final remoteTable = entry.value;

        final recordsToSync = await getRecordsNeedingSync(localTable);

        if (recordsToSync.isNotEmpty) {
          final (creates, updates, deletes) = _categorizeRecords(recordsToSync);

          // Handle creates and updates
          if (creates.isNotEmpty || updates.isNotEmpty) {
            final upsertRecords = <Map<String, dynamic>>[];
            for (final record in [...creates, ...updates]) {
              final supabaseId = await _ensureSupabaseIdValue(
                localTable,
                record,
              );
              final remoteRecord = await _convertLocalToRemote(
                localTable,
                record,
                supabaseId,
              );
              upsertRecords.add(remoteRecord);
            }

            final uploadedRecords = await _supabaseService.upsertRecords(
              remoteTable,
              upsertRecords,
            );

            // Update local records with remote data
            await _markRecordsAsSynced(localTable, [
              ...creates,
              ...updates,
            ], uploadedRecords);
          }

          // Handle deletes
          if (deletes.isNotEmpty) {
            final supabaseIds = deletes
                .map((r) => _getField<String>(r, 'supabaseId'))
                .whereType<String>()
                .toList();
            final ids = deletes
                .map((r) => _getField<int>(r, 'id'))
                .whereType<int>()
                .toList();

            if (supabaseIds.isNotEmpty) {
              await _supabaseService.deleteRecords(remoteTable, supabaseIds);
            }

            // Mark local deletes as synced
            await _markRecordsAsSynced(localTable, deletes, []);

            // delete records locally
            await _deleteLocalRecordsByIds(localTable, ids);
          }

          tableStats[localTable] = recordsToSync.length;
          totalRecords += recordsToSync.length;
        }
      }

      // Trigger callback to invalidate providers and refresh UI after push
      _notifyProviderInvalidation();

      return SyncResult(
        success: true,
        recordsSynced: totalRecords,
        tableStats: tableStats,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Pull remote changes and apply to local database
  Future<SyncResult> _pullRemoteChanges() async {
    int totalRecords = 0;
    Map<String, int> tableStats = {};

    try {
      // for every table
      for (final entry in _tableMapping.entries) {
        final localTable = entry.key;
        final remoteTable = entry.value;

        // Fetch remote records modified since last sync
        final remoteRecords = await _supabaseService.fetchRecords(
          remoteTable,
          userId: _supabaseService.currentUserId,
          lastSyncTime: _lastSyncTime,
        );

        if (remoteRecords.isNotEmpty) {
          // Log deleted records specifically
          final deletedCount = remoteRecords
              .where((r) => r['is_deleted'] == true || r['is_deleted'] == 1)
              .length;
          if (deletedCount > 0) {
          } else {}

          for (final remoteRecord in remoteRecords) {
            await _applyRemoteChangeToLocal(localTable, remoteRecord);
          }

          tableStats[localTable] = remoteRecords.length;
          totalRecords += remoteRecords.length;
        } else {}
      }

      // Trigger callback to invalidate providers and refresh UI with new data
      _notifyProviderInvalidation();

      return SyncResult(
        success: true,
        recordsSynced: totalRecords,
        tableStats: tableStats,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Helper methods
  void _updateStatus(SyncStatus status) {
    final oldStatus = _currentStatus;

    // Only update if status actually changed to prevent unnecessary rebuilds
    if (oldStatus != status) {
      _currentStatus = status;

      // Log status changes for debugging

      // Cancel any pending status update
      _statusDebounceTimer?.cancel();

      // For critical status changes (syncing), update immediately
      // For others, debounce to prevent rapid successive updates
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

  void _notifyStatusChange(SyncStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  /// Update sync result and notify listeners
  void _updateSyncResult(SyncResult? result) {
    // Only update if result is different to prevent unnecessary rebuilds
    if (_lastSyncResult != result) {
      _lastSyncResult = result;
      if (!_resultController.isClosed) {
        _resultController.add(result);
      }
    }
  }

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

      return null; // Will be null for first sync
    } catch (e) {
      return null;
    }
  }

  /// Save last sync timestamp to local storage
  Future<void> _saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_time', time.toIso8601String());
  }

  /// Clear the stored last sync time - useful when resetting sync state
  /// This will force a full sync on the next sync operation
  Future<void> clearLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_time');
    _lastSyncTime = null;
  }

  /// Get records that need to be synced for a given table
  Future<List<Map<String, dynamic>>> getRecordsNeedingSync(
    String tableName,
  ) async {
    try {
      switch (tableName) {
        case 'task':
          final tasks = await (_database.select(
            _database.task,
          )..where((t) => t.needsSync.equals(true))).get();
          return tasks.map((t) => t.toJson()).toList();

        case 'project':
          final projects = await (_database.select(
            _database.project,
          )..where((p) => p.needsSync.equals(true))).get();
          return projects.map((p) => p.toJson()).toList();

        case 'project_category':
          final categories = await (_database.select(
            _database.projectCategory,
          )..where((pc) => pc.needsSync.equals(true))).get();
          return categories.map((pc) => pc.toJson()).toList();

        case 'block':
          final blocks = await (_database.select(
            _database.block,
          )..where((b) => b.needsSync.equals(true))).get();
          return blocks.map((b) => b.toJson()).toList();

        case 'task_completion':
          final completions = await (_database.select(
            _database.taskCompletion,
          )..where((tc) => tc.needsSync.equals(true))).get();
          return completions.map((tc) => tc.toJson()).toList();

        case 'block_completion':
          final completions = await (_database.select(
            _database.blockCompletion,
          )..where((bc) => bc.needsSync.equals(true))).get();
          return completions.map((bc) => bc.toJson()).toList();

        case 'block_task':
          final blockTasks = await (_database.select(
            _database.blockTask,
          )..where((bt) => bt.needsSync.equals(true))).get();
          return blockTasks.map((bt) => bt.toJson()).toList();

        case 'settings':
          final settings = await (_database.select(
            _database.settings,
          )..where((s) => s.needsSync.equals(true))).get();
          return settings.map((s) => s.toJson()).toList();

        default:
          return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Get count of records needing sync across all tables
  Future<int> getPendingSyncCount() async {
    int count = 0;
    for (final tableName in _tableMapping.keys) {
      final records = await getRecordsNeedingSync(tableName);
      count += records.length;
    }
    return count;
  }

  /// Check if sync is needed (has pending changes)
  Future<bool> needsSync() async {
    return (await getPendingSyncCount()) > 0;
  }

  // Helper methods for sync operations

  /// Get all records from a local table for initial migration reconciliation
  Future<List<Map<String, dynamic>>> _getAllRecords(String tableName) async {
    try {
      switch (tableName) {
        case 'task':
          final tasks = await _database.select(_database.task).get();
          return tasks.map((t) => t.toJson()).toList();

        case 'project':
          final projects = await _database.select(_database.project).get();
          return projects.map((p) => p.toJson()).toList();

        case 'project_category':
          final categories = await _database
              .select(_database.projectCategory)
              .get();
          return categories.map((pc) => pc.toJson()).toList();

        case 'block':
          final blocks = await _database.select(_database.block).get();
          return blocks.map((b) => b.toJson()).toList();

        case 'task_completion':
          final completions = await _database
              .select(_database.taskCompletion)
              .get();
          return completions.map((tc) => tc.toJson()).toList();

        case 'block_completion':
          final completions = await _database
              .select(_database.blockCompletion)
              .get();
          return completions.map((bc) => bc.toJson()).toList();

        case 'block_task':
          final blockTasks = await _database.select(_database.blockTask).get();
          return blockTasks.map((bt) => bt.toJson()).toList();

        case 'settings':
          final settings = await _database.select(_database.settings).get();
          return settings.map((s) => s.toJson()).toList();

        default:
          return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Convert local record to remote format
  Future<Map<String, dynamic>> _convertLocalToRemote(
    String tableName,
    Map<String, dynamic> localRecord,
    String supabaseId,
  ) async {
    final remoteRecord = <String, dynamic>{};
    final overrides =
        _columnNameOverrides[tableName] ?? const <String, String>{};

    localRecord.forEach((key, value) {
      if (key == 'id') {
        return; // never sync local primary keys
      }

      final remoteKey = overrides[key] ?? _toSnakeCase(key);
      remoteRecord[remoteKey] = _normalizeValue(value, fieldName: remoteKey);
    });

    // Ensure required metadata is present
    remoteRecord['supabase_id'] = remoteRecord['supabase_id'] ?? supabaseId;
    remoteRecord['user_id'] = _supabaseService.currentUserId;
    remoteRecord['last_modified'] =
        remoteRecord['last_modified'] ??
        _normalizeValue(
          localRecord['lastModified'] ?? DateTime.now().toIso8601String(),
          fieldName: 'last_modified',
        );

    final relationFields = await _buildRelationFields(
      tableName,
      localRecord,
      supabaseId,
    );
    remoteRecord.addAll(relationFields);

    return remoteRecord;
  }

  static const Set<String> _timestampFieldNames = {
    'start_date',
    'deadline',
    'last_modified',
    'day_local',
    'created_at',
    'updated_at',
    'completed_at',
    'start_time',
    'end_time',
  };
  static const Set<String> _colorFieldNames = {'color'};

  dynamic _normalizeValue(dynamic value, {String? fieldName}) {
    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (fieldName != null && _colorFieldNames.contains(fieldName)) {
      final colorInt = _coerceToInt(value);
      if (colorInt != null) {
        return _toSigned32Bit(colorInt);
      }
    }

    final intValue = _coerceToInt(value);
    if (intValue != null && _shouldTreatAsEpoch(intValue, fieldName)) {
      final dateTime = intValue > 100000000000
          ? DateTime.fromMillisecondsSinceEpoch(intValue)
          : DateTime.fromMillisecondsSinceEpoch(intValue * 1000);
      return dateTime.toIso8601String();
    }

    return value;
  }

  int? _coerceToInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.round();
    return null;
  }

  bool _shouldTreatAsEpoch(int value, String? fieldName) {
    if (fieldName != null && _timestampFieldNames.contains(fieldName)) {
      return true;
    }

    // Heuristic: treat large positive ints as epoch timestamps
    if (value <= 0) return false;
    // Seconds range roughly between 2001 and 2099
    if (value >= 1000000000 && value <= 4102444800) {
      return true;
    }
    // Milliseconds for reasonable dates
    if (value >= 1000000000000 && value <= 4102444800000) {
      return true;
    }
    return false;
  }

  int _toSigned32Bit(int value) {
    const maxSigned = 0x7fffffff;
    const minSigned = -0x80000000;
    const mod = 0x100000000;
    if (value > maxSigned) {
      return value - mod;
    }
    if (value < minSigned) {
      return value + mod;
    }
    return value;
  }

  int? _restoreUnsignedColor(dynamic value) {
    final intValue = _coerceToInt(value);
    if (intValue == null) return null;
    const mod = 0x100000000;
    return intValue < 0 ? intValue + mod : intValue;
  }

  T? _getField<T>(Map<String, dynamic> record, String camelCaseKey) {
    if (record.containsKey(camelCaseKey)) {
      return record[camelCaseKey] as T?;
    }
    final snakeKey = _toSnakeCase(camelCaseKey);
    if (record.containsKey(snakeKey)) {
      return record[snakeKey] as T?;
    }
    return null;
  }

  String _toSnakeCase(String input) {
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (_isUpperCase(char) && i != 0 && input[i - 1] != '_') {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  bool _isUpperCase(String char) {
    return char.toUpperCase() == char && char.toLowerCase() != char;
  }

  static const Map<String, Map<String, String>> _columnNameOverrides = {
    'block_task': {'blockId': 'block_id', 'taskId': 'task_id'},
  };

  Future<Map<String, dynamic>> _buildRelationFields(
    String tableName,
    Map<String, dynamic> localRecord,
    String supabaseId,
  ) async {
    final relationFields = <String, dynamic>{};

    switch (tableName) {
      case 'task':
        final projectSupabaseId = await _getSupabaseIdForLocal(
          'project',
          _getField<int>(localRecord, 'projectId'),
        );
        final parentTaskSupabaseId = await _getSupabaseIdForLocal(
          'task',
          _getField<int>(localRecord, 'parentTaskId'),
        );
        if (projectSupabaseId == null) {
        } else {
          relationFields['project_supabase_id'] = projectSupabaseId;
        }
        if (parentTaskSupabaseId != null) {
          relationFields['parent_task_supabase_id'] = parentTaskSupabaseId;
        }
        break;
      case 'project':
        final parentProjectSupabaseId = await _getSupabaseIdForLocal(
          'project',
          _getField<int>(localRecord, 'parentProjectId'),
        );
        final categorySupabaseId = await _getSupabaseIdForLocal(
          'project_category',
          _getField<int>(localRecord, 'category'),
        );
        if (parentProjectSupabaseId != null) {
          relationFields['parent_project_supabase_id'] =
              parentProjectSupabaseId;
        }
        if (categorySupabaseId != null) {
          relationFields['category_supabase_id'] = categorySupabaseId;
        }
        break;
      case 'block':
        final projectSupabaseId = await _getSupabaseIdForLocal(
          'project',
          _getField<int>(localRecord, 'projectId'),
        );
        if (projectSupabaseId == null) {
        } else {
          relationFields['project_supabase_id'] = projectSupabaseId;
        }
        break;
      case 'block_task':
        final blockSupabaseId = await _getSupabaseIdForLocal(
          'block',
          _getField<int>(localRecord, 'blockId'),
        );
        final taskSupabaseId = await _getSupabaseIdForLocal(
          'task',
          _getField<int>(localRecord, 'taskId'),
        );
        if (blockSupabaseId == null || taskSupabaseId == null) {
        } else {
          relationFields['block_supabase_id'] = blockSupabaseId;
          relationFields['task_supabase_id'] = taskSupabaseId;
        }
        break;
      case 'task_completion':
        final taskSupabaseId = await _getSupabaseIdForLocal(
          'task',
          _getField<int>(localRecord, 'taskId'),
        );
        if (taskSupabaseId == null) {
        } else {
          relationFields['task_supabase_id'] = taskSupabaseId;
        }
        break;
      case 'block_completion':
        final blockSupabaseId = await _getSupabaseIdForLocal(
          'block',
          _getField<int>(localRecord, 'blockId'),
        );
        if (blockSupabaseId == null) {
        } else {
          relationFields['block_supabase_id'] = blockSupabaseId;
        }
        break;
      default:
        break;
    }

    relationFields.removeWhere((key, value) => value == null);
    return relationFields;
  }

  Future<String?> _getSupabaseIdForLocal(String tableName, int? localId) async {
    if (localId == null) return null;
    final cache = _localToSupabaseCache.putIfAbsent(tableName, () => {});
    if (cache.containsKey(localId)) {
      return cache[localId];
    }

    String? supabaseId;
    switch (tableName) {
      case 'task':
        supabaseId = (await (_database.select(
          _database.task,
        )..where((t) => t.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'project':
        supabaseId = (await (_database.select(
          _database.project,
        )..where((p) => p.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'project_category':
        supabaseId = (await (_database.select(
          _database.projectCategory,
        )..where((pc) => pc.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'block':
        supabaseId = (await (_database.select(
          _database.block,
        )..where((b) => b.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'task_completion':
        supabaseId = (await (_database.select(
          _database.taskCompletion,
        )..where((tc) => tc.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'block_completion':
        supabaseId = (await (_database.select(
          _database.blockCompletion,
        )..where((bc) => bc.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      case 'settings':
        supabaseId = (await (_database.select(
          _database.settings,
        )..where((s) => s.id.equals(localId))).getSingleOrNull())?.supabaseId;
        break;
      default:
        break;
    }

    cache[localId] = supabaseId;
    return supabaseId;
  }

  Future<int?> _getLocalIdForSupabase(
    String tableName,
    String? supabaseId,
  ) async {
    if (supabaseId == null) return null;
    final cache = _supabaseToLocalCache.putIfAbsent(tableName, () => {});
    if (cache.containsKey(supabaseId)) {
      return cache[supabaseId];
    }

    int? localId;
    switch (tableName) {
      case 'task':
        localId =
            (await (_database.select(_database.task)
                      ..where((t) => t.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'project':
        localId =
            (await (_database.select(_database.project)
                      ..where((p) => p.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'project_category':
        localId =
            (await (_database.select(_database.projectCategory)
                      ..where((pc) => pc.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'block':
        localId =
            (await (_database.select(_database.block)
                      ..where((b) => b.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'task_completion':
        localId =
            (await (_database.select(_database.taskCompletion)
                      ..where((tc) => tc.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'block_completion':
        localId =
            (await (_database.select(_database.blockCompletion)
                      ..where((bc) => bc.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      case 'settings':
        localId =
            (await (_database.select(_database.settings)
                      ..where((s) => s.supabaseId.equals(supabaseId)))
                    .getSingleOrNull())
                ?.id;
        break;
      default:
        break;
    }

    if (localId != null) {
      cache[supabaseId] = localId;
    }
    return localId;
  }

  Future<String> _ensureSupabaseIdValue(
    String tableName,
    Map<String, dynamic> record,
  ) async {
    final existing = _getField<String>(record, 'supabaseId');
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newId = _uuid.v4();
    await _setLocalSupabaseId(tableName, record, newId);
    record['supabaseId'] = newId;
    return newId;
  }

  Future<void> _setLocalSupabaseId(
    String tableName,
    Map<String, dynamic> record,
    String supabaseId,
  ) async {
    if (tableName == 'block_task') {
      final blockId = _getField<int>(record, 'blockId');
      final taskId = _getField<int>(record, 'taskId');
      if (blockId != null && taskId != null) {
        await _setBlockTaskSupabaseId(blockId, taskId, supabaseId);
      }
      return;
    }

    final localId = _getField<int>(record, 'id');
    if (localId == null) return;
    await _setRecordSupabaseId(tableName, localId, supabaseId);
  }

  Future<void> _setRecordSupabaseId(
    String tableName,
    int localId,
    String supabaseId,
  ) async {
    switch (tableName) {
      case 'task':
        await (_database.update(_database.task)
              ..where((t) => t.id.equals(localId)))
            .write(TaskCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'project':
        await (_database.update(_database.project)
              ..where((p) => p.id.equals(localId)))
            .write(ProjectCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'project_category':
        await (_database.update(_database.projectCategory)
              ..where((pc) => pc.id.equals(localId)))
            .write(ProjectCategoryCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'block':
        await (_database.update(_database.block)
              ..where((b) => b.id.equals(localId)))
            .write(BlockCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'task_completion':
        await (_database.update(_database.taskCompletion)
              ..where((tc) => tc.id.equals(localId)))
            .write(TaskCompletionCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'block_completion':
        await (_database.update(_database.blockCompletion)
              ..where((bc) => bc.id.equals(localId)))
            .write(BlockCompletionCompanion(supabaseId: Value(supabaseId)));
        break;
      case 'settings':
        await (_database.update(_database.settings)
              ..where((s) => s.id.equals(localId)))
            .write(SettingsCompanion(supabaseId: Value(supabaseId)));
        break;
      default:
        break;
    }

    _localToSupabaseCache.putIfAbsent(tableName, () => {})[localId] =
        supabaseId;
    _supabaseToLocalCache.putIfAbsent(tableName, () => {})[supabaseId] =
        localId;
  }

  Future<void> _setBlockTaskSupabaseId(
    int blockId,
    int taskId,
    String supabaseId,
  ) async {
    await (_database.update(
          _database.blockTask,
        )..where((bt) => bt.blockId.equals(blockId) & bt.taskId.equals(taskId)))
        .write(BlockTaskCompanion(supabaseId: Value(supabaseId)));
  }

  Future<int?> _resolveLocalId(
    String tableName,
    Map<String, dynamic> remoteRecord,
    String remoteCamelCaseKey,
  ) async {
    final supabaseId = _getField<String>(remoteRecord, remoteCamelCaseKey);
    return _getLocalIdForSupabase(tableName, supabaseId);
  }

  /// Update local records with supabase_ids after migration
  Future<void> _updateLocalWithRemoteIds(
    String tableName,
    List<Map<String, dynamic>> localRecords,
    List<Map<String, dynamic>> uploadedRecords,
  ) async {
    // Match local records with uploaded records and update supabase_id
    for (
      int i = 0;
      i < localRecords.length && i < uploadedRecords.length;
      i++
    ) {
      final localRecord = localRecords[i];
      final uploadedRecord = uploadedRecords[i];
      final supabaseId = uploadedRecord['supabase_id'] as String;

      if (tableName == 'block_task') {
        // Handle BlockTask with composite key
        final blockId = _getField<int>(localRecord, 'blockId');
        final taskId = _getField<int>(localRecord, 'taskId');
        if (blockId == null || taskId == null) {
          continue;
        }
        await _updateBlockTaskSupabaseId(blockId, taskId, supabaseId);
      } else {
        // Handle other tables with single ID
        final localId = _getField<int>(localRecord, 'id');
        if (localId == null) {
          continue;
        }
        await _updateRecordSupabaseId(tableName, localId, supabaseId);
      }
    }
  }

  /// Update a specific record's supabase_id
  Future<void> _updateRecordSupabaseId(
    String tableName,
    int localId,
    String supabaseId,
  ) async {
    final now = DateTime.now();

    switch (tableName) {
      case 'task':
        await (_database.update(
          _database.task,
        )..where((t) => t.id.equals(localId))).write(
          TaskCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'project':
        await (_database.update(
          _database.project,
        )..where((p) => p.id.equals(localId))).write(
          ProjectCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'project_category':
        await (_database.update(
          _database.projectCategory,
        )..where((pc) => pc.id.equals(localId))).write(
          ProjectCategoryCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'block':
        await (_database.update(
          _database.block,
        )..where((b) => b.id.equals(localId))).write(
          BlockCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'task_completion':
        await (_database.update(
          _database.taskCompletion,
        )..where((tc) => tc.id.equals(localId))).write(
          TaskCompletionCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'block_completion':
        await (_database.update(
          _database.blockCompletion,
        )..where((bc) => bc.id.equals(localId))).write(
          BlockCompletionCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      case 'block_task':
        // BlockTask has composite key, need to find by localId first
        // Since BlockTask doesn't have a traditional single ID, we need to find the record differently
        final blockTaskRecord =
            await (_database.select(_database.blockTask)..where(
                  (bt) => bt.blockId.equals(localId),
                )) // This is a workaround - localId represents blockId in this context
                .getSingleOrNull();
        if (blockTaskRecord != null) {
          await (_database.update(_database.blockTask)..where(
                (bt) =>
                    bt.blockId.equals(blockTaskRecord.blockId) &
                    bt.taskId.equals(blockTaskRecord.taskId),
              ))
              .write(
                BlockTaskCompanion(
                  supabaseId: Value(supabaseId),
                  needsSync: const Value(false),
                  lastModified: Value(now),
                ),
              );
        } else {}
        break;
      case 'settings':
        await (_database.update(
          _database.settings,
        )..where((s) => s.id.equals(localId))).write(
          SettingsCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
        break;
      default:
    }

    _localToSupabaseCache.putIfAbsent(tableName, () => {})[localId] =
        supabaseId;
    _supabaseToLocalCache.putIfAbsent(tableName, () => {})[supabaseId] =
        localId;
  }

  /// Categorize records into creates, updates, and deletes
  (
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
    List<Map<String, dynamic>>,
  )
  _categorizeRecords(List<Map<String, dynamic>> records) {
    final creates = <Map<String, dynamic>>[];
    final updates = <Map<String, dynamic>>[];
    final deletes = <Map<String, dynamic>>[];

    for (final record in records) {
      final rawDeleted = _getField<dynamic>(record, 'isDeleted');
      final isDeleted = rawDeleted == true || rawDeleted == 1;
      final hasSupabaseId = _getField<String>(record, 'supabaseId') != null;

      if (isDeleted) {
        deletes.add(record);
      } else if (hasSupabaseId) {
        updates.add(record);
      } else {
        creates.add(record);
      }
    }

    return (creates, updates, deletes);
  }

  /// Mark records as synced (set needs_sync = false)
  Future<void> _markRecordsAsSynced(
    String tableName,
    List<Map<String, dynamic>> records,
    List<Map<String, dynamic>> uploadedRecords,
  ) async {
    try {
      // Use batch operation for better performance
      await _batchMarkRecordsAsSynced(tableName, records);
    } catch (e) {
      // Fallback to individual marking
      for (final record in records) {
        final localId = _getField<int>(record, 'id');
        if (localId != null) {
          await _markSingleRecordAsSynced(tableName, localId);
        }
      }
    }
  }

  /// Mark a single record as synced
  Future<void> _markSingleRecordAsSynced(String tableName, int localId) async {
    switch (tableName) {
      case 'task':
        await (_database.update(_database.task)
              ..where((t) => t.id.equals(localId)))
            .write(const TaskCompanion(needsSync: Value(false)));
        break;
      case 'project':
        await (_database.update(_database.project)
              ..where((p) => p.id.equals(localId)))
            .write(const ProjectCompanion(needsSync: Value(false)));
        break;
      case 'project_category':
        await (_database.update(_database.projectCategory)
              ..where((pc) => pc.id.equals(localId)))
            .write(const ProjectCategoryCompanion(needsSync: Value(false)));
        break;
      case 'block':
        await (_database.update(_database.block)
              ..where((b) => b.id.equals(localId)))
            .write(const BlockCompanion(needsSync: Value(false)));
        break;
      case 'task_completion':
        await (_database.update(_database.taskCompletion)
              ..where((tc) => tc.id.equals(localId)))
            .write(const TaskCompletionCompanion(needsSync: Value(false)));
        break;
      case 'block_completion':
        await (_database.update(_database.blockCompletion)
              ..where((bc) => bc.id.equals(localId)))
            .write(const BlockCompletionCompanion(needsSync: Value(false)));
        break;
      case 'block_task':
        // BlockTask has composite key, need to find by some identifier
        // Since BlockTask doesn't have a traditional single ID, this is a design issue
        // For now, we'll skip this and log a warning
        break;
      case 'settings':
        await (_database.update(_database.settings)
              ..where((s) => s.id.equals(localId)))
            .write(const SettingsCompanion(needsSync: Value(false)));
        break;
      default:
    }
  }

  /// Apply a remote change to local database with conflict resolution
  Future<void> _applyRemoteChangeToLocal(
    String tableName,
    Map<String, dynamic> remoteRecord,
  ) async {
    try {
      final supabaseId = remoteRecord['supabase_id'] as String?;
      if (supabaseId == null) {
        return;
      }

      // Check if local record exists
      final existingLocal = await _findLocalRecordBySupabaseId(
        tableName,
        supabaseId,
      );

      // Parse remote timestamps
      final remoteModified = _parseDateTime(remoteRecord['last_modified']);
      final remoteVersion = remoteRecord['version'] as int? ?? 1;
      final isRemoteDeleted =
          remoteRecord['is_deleted'] == true || remoteRecord['is_deleted'] == 1;

      if (existingLocal == null) {
        // No local record exists - insert if not deleted
        if (!isRemoteDeleted) {
          await _insertRemoteRecord(tableName, remoteRecord);
        }
        return;
      }

      // Local record exists - resolve conflicts
      final localModified = existingLocal['last_modified'] as DateTime?;
      final localVersion = existingLocal['version'] as int? ?? 1;
      final localNeedsSync = existingLocal['needs_sync'] as bool? ?? false;
      final requiresLocalId = tableName != 'block_task';
      final int? localId = requiresLocalId ? existingLocal['id'] as int? : null;

      if (requiresLocalId && localId == null) {
        return;
      }

      // Handle remote deletion early if record is marked as deleted
      if (isRemoteDeleted) {
        if (tableName == 'block_task') {
          await _deleteBlockTaskBySupabaseId(supabaseId);
        } else {
          // Use localId for deletion, not remoteRecord['id']
          await _deleteLocalRecordsByIds(tableName, [localId!]);
        }
        return;
      }

      // Conflict resolution strategy for non-deleted records
      if (localNeedsSync) {
        // Local has pending changes - use version-based resolution
        if (remoteVersion > localVersion) {
          // Remote is newer - apply remote changes but preserve local if more recent
          if (remoteModified != null && localModified != null) {
            if (remoteModified.isAfter(localModified)) {
              await _updateLocalWithRemote(
                tableName,
                tableName == 'block_task' ? 0 : localId!,
                remoteRecord,
              );
            } else {}
          } else {
            await _updateLocalWithRemote(
              tableName,
              tableName == 'block_task' ? 0 : localId!,
              remoteRecord,
            );
          }
        } else {}
      } else {
        // No local pending changes - safe to apply remote
        await _updateLocalWithRemote(
          tableName,
          tableName == 'block_task' ? 0 : localId!,
          remoteRecord,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Find local record by supabase_id
  Future<Map<String, dynamic>?> _findLocalRecordBySupabaseId(
    String tableName,
    String supabaseId,
  ) async {
    try {
      switch (tableName) {
        case 'task':
          final result = await (_database.select(
            _database.task,
          )..where((t) => t.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'project':
          final result = await (_database.select(
            _database.project,
          )..where((p) => p.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'project_category':
          final result = await (_database.select(
            _database.projectCategory,
          )..where((pc) => pc.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'block':
          final result = await (_database.select(
            _database.block,
          )..where((b) => b.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'task_completion':
          final result = await (_database.select(
            _database.taskCompletion,
          )..where((tc) => tc.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'block_completion':
          final result = await (_database.select(
            _database.blockCompletion,
          )..where((bc) => bc.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'block_task':
          final result = await (_database.select(
            _database.blockTask,
          )..where((bt) => bt.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        case 'settings':
          final result = await (_database.select(
            _database.settings,
          )..where((s) => s.supabaseId.equals(supabaseId))).getSingleOrNull();
          return result?.toJson();
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Insert new record from remote data
  Future<void> _insertRemoteRecord(
    String tableName,
    Map<String, dynamic> remoteRecord,
  ) async {
    final now = DateTime.now();

    switch (tableName) {
      case 'task':
        final projectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'projectSupabaseId',
        );
        if (projectLocalId == null) {
          break;
        }
        final parentTaskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'parentTaskSupabaseId',
        );

        await _database
            .into(_database.task)
            .insert(
              TaskCompanion(
                name: Value(remoteRecord['name'] as String),
                projectId: Value(projectLocalId),
                unit: Value(remoteRecord['unit'] as String?),
                startPoint: Value(remoteRecord['start_point'] as int? ?? 0),
                current: Value(remoteRecord['current'] as int? ?? 0),
                endGoal: Value(remoteRecord['end_goal'] as int? ?? 1),
                deadline: Value(_parseDateTime(remoteRecord['deadline'])),
                isCompleted: Value(
                  remoteRecord['is_completed'] as bool? ?? false,
                ),
                completedAt: Value(
                  _parseDateTime(remoteRecord['completed_at']),
                ),
                parentTaskId: Value(parentTaskLocalId),
                orderIndex: Value(remoteRecord['order_index'] as int? ?? 0),
                depth: Value(remoteRecord['depth'] as int? ?? 0),
                supabaseId: Value(remoteRecord['supabase_id'] as String),
                lastModified: Value(
                  _parseDateTime(remoteRecord['last_modified']) ?? now,
                ),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;
      case 'project':
        final parentProjectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'parentProjectSupabaseId',
        );
        final categoryLocalId = await _resolveLocalId(
          'project_category',
          remoteRecord,
          'categorySupabaseId',
        );

        await _database
            .into(_database.project)
            .insert(
              ProjectCompanion(
                parentProjectId: Value(parentProjectLocalId),
                name: Value(remoteRecord['name'] as String),
                startDate: Value(_parseDateTime(remoteRecord['start_date'])!),
                deadline: Value(_parseDateTime(remoteRecord['deadline'])!),
                startPoint: Value(remoteRecord['start_point'] as int? ?? 0),
                current: Value(remoteRecord['current'] as int? ?? 0),
                goal: Value(remoteRecord['goal'] as int? ?? 1),
                unit: Value(remoteRecord['unit'] as String? ?? ""),
                category: Value(categoryLocalId),
                color: Value(_restoreUnsignedColor(remoteRecord['color'])),
                supabaseId: Value(remoteRecord['supabase_id'] as String),
                lastModified: Value(
                  _parseDateTime(remoteRecord['last_modified']) ?? now,
                ),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;
      case 'project_category':
        await _database
            .into(_database.projectCategory)
            .insert(
              ProjectCategoryCompanion(
                title: Value(remoteRecord['title'] as String?),
                iconCodePoint: Value(remoteRecord['icon_code_point'] as int?),
                orderIndex: Value(remoteRecord['order_index'] as int?),
                supabaseId: Value(remoteRecord['supabase_id'] as String),
                lastModified: Value(
                  _parseDateTime(remoteRecord['last_modified']) ?? now,
                ),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;
      case 'block':
        final projectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'projectSupabaseId',
        );
        if (projectLocalId == null) {
          break;
        }
        await _database
            .into(_database.block)
            .insert(
              BlockCompanion(
                projectId: Value(projectLocalId),
                dayLocal: Value(_parseDateTime(remoteRecord['day_local'])!),
                startMinuteOfDay: Value(
                  remoteRecord['start_minute_of_day'] as int,
                ),
                lengthMinutes: Value(remoteRecord['length_minutes'] as int),
                supabaseId: Value(remoteRecord['supabase_id'] as String),
                lastModified: Value(
                  _parseDateTime(remoteRecord['last_modified']) ?? now,
                ),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;
      case 'task_completion':
        final taskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'taskSupabaseId',
        );
        if (taskLocalId == null) {
          break;
        }
        await _database
            .into(_database.taskCompletion)
            .insert(
              TaskCompletionCompanion(
                taskId: Value(taskLocalId),
                count: Value(remoteRecord['count'] as int),
                completedAt: Value(
                  _parseDateTime(remoteRecord['completed_at'])!,
                ),
                supabaseId: Value(remoteRecord['supabase_id'] as String),
                lastModified: Value(
                  _parseDateTime(remoteRecord['last_modified']) ?? now,
                ),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;
      case 'block_completion':
        final blockLocalId = await _resolveLocalId(
          'block',
          remoteRecord,
          'blockSupabaseId',
        );
        if (blockLocalId == null) {
          break;
        }
        await _database
            .into(_database.blockCompletion)
            .insert(
              BlockCompletionCompanion(
                blockId: Value(blockLocalId),
                count: Value(remoteRecord['count'] as int),
                completedAt: Value(
                  _parseDateTime(remoteRecord['completed_at'])!,
                ),
                supabaseId: Value(remoteRecord['supabase_id'] as String),
                lastModified: Value(
                  _parseDateTime(remoteRecord['last_modified']) ?? now,
                ),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;
      case 'block_task':
        final blockLocalId = await _resolveLocalId(
          'block',
          remoteRecord,
          'blockSupabaseId',
        );
        final taskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'taskSupabaseId',
        );
        if (blockLocalId == null || taskLocalId == null) {
          break;
        }
        await _database
            .into(_database.blockTask)
            .insert(
              BlockTaskCompanion(
                blockId: Value(blockLocalId),
                taskId: Value(taskLocalId),
                supabaseId: Value(remoteRecord['supabase_id'] as String),
                lastModified: Value(
                  _parseDateTime(remoteRecord['last_modified']) ?? now,
                ),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;
      case 'settings':
        await _database
            .into(_database.settings)
            .insert(
              SettingsCompanion(
                id: const Value(1), // Settings table must have id = 1
                defaultStartTime: Value(
                  remoteRecord['default_start_time'] as int,
                ),
                defaultTaskLength: Value(
                  remoteRecord['default_task_length'] as int,
                ),
                defaultBreakTime: Value(
                  remoteRecord['default_break_time'] as int,
                ),
                supabaseId: Value(remoteRecord['supabase_id'] as String),
                lastModified: Value(
                  _parseDateTime(remoteRecord['last_modified']) ?? now,
                ),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;
      default:
    }
  }

  /// Update local record with remote data
  Future<void> _updateLocalWithRemote(
    String tableName,
    int localId,
    Map<String, dynamic> remoteRecord,
  ) async {
    final now = DateTime.now();

    switch (tableName) {
      case 'task':
        final projectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'projectSupabaseId',
        );
        if (projectLocalId == null) {
          break;
        }
        final parentTaskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'parentTaskSupabaseId',
        );
        await (_database.update(
          _database.task,
        )..where((t) => t.id.equals(localId))).write(
          TaskCompanion(
            name: Value(remoteRecord['name'] as String),
            projectId: Value(projectLocalId),
            unit: Value(remoteRecord['unit'] as String?),
            startPoint: Value(remoteRecord['start_point'] as int? ?? 0),
            current: Value(remoteRecord['current'] as int? ?? 0),
            endGoal: Value(remoteRecord['end_goal'] as int? ?? 1),
            deadline: Value(_parseDateTime(remoteRecord['deadline'])),
            isCompleted: Value(remoteRecord['is_completed'] as bool? ?? false),
            completedAt: Value(_parseDateTime(remoteRecord['completed_at'])),
            parentTaskId: Value(parentTaskLocalId),
            orderIndex: Value(remoteRecord['order_index'] as int? ?? 0),
            depth: Value(remoteRecord['depth'] as int? ?? 0),
            lastModified: Value(
              _parseDateTime(remoteRecord['last_modified']) ?? now,
            ),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;
      case 'project':
        final parentProjectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'parentProjectSupabaseId',
        );
        final categoryLocalId = await _resolveLocalId(
          'project_category',
          remoteRecord,
          'categorySupabaseId',
        );
        await (_database.update(
          _database.project,
        )..where((p) => p.id.equals(localId))).write(
          ProjectCompanion(
            parentProjectId: Value(parentProjectLocalId),
            name: Value(remoteRecord['name'] as String),
            startDate: Value(_parseDateTime(remoteRecord['start_date'])!),
            deadline: Value(_parseDateTime(remoteRecord['deadline'])!),
            startPoint: Value(remoteRecord['start_point'] as int? ?? 0),
            current: Value(remoteRecord['current'] as int? ?? 0),
            goal: Value(remoteRecord['goal'] as int? ?? 1),
            unit: Value(remoteRecord['unit'] as String? ?? ""),
            category: Value(categoryLocalId),
            color: Value(_restoreUnsignedColor(remoteRecord['color'])),
            lastModified: Value(
              _parseDateTime(remoteRecord['last_modified']) ?? now,
            ),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;
      case 'project_category':
        await (_database.update(
          _database.projectCategory,
        )..where((pc) => pc.id.equals(localId))).write(
          ProjectCategoryCompanion(
            title: Value(remoteRecord['title'] as String?),
            iconCodePoint: Value(remoteRecord['icon_code_point'] as int?),
            orderIndex: Value(remoteRecord['order_index'] as int?),
            lastModified: Value(
              _parseDateTime(remoteRecord['last_modified']) ?? now,
            ),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;
      case 'block':
        final projectLocalId = await _resolveLocalId(
          'project',
          remoteRecord,
          'projectSupabaseId',
        );
        if (projectLocalId == null) {
          break;
        }
        await (_database.update(
          _database.block,
        )..where((b) => b.id.equals(localId))).write(
          BlockCompanion(
            projectId: Value(projectLocalId),
            dayLocal: Value(_parseDateTime(remoteRecord['day_local'])!),
            startMinuteOfDay: Value(remoteRecord['start_minute_of_day'] as int),
            lengthMinutes: Value(remoteRecord['length_minutes'] as int),
            lastModified: Value(
              _parseDateTime(remoteRecord['last_modified']) ?? now,
            ),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;
      case 'task_completion':
        final taskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'taskSupabaseId',
        );
        if (taskLocalId == null) {
          break;
        }
        await (_database.update(
          _database.taskCompletion,
        )..where((tc) => tc.id.equals(localId))).write(
          TaskCompletionCompanion(
            taskId: Value(taskLocalId),
            count: Value(remoteRecord['count'] as int),
            completedAt: Value(_parseDateTime(remoteRecord['completed_at'])!),
            lastModified: Value(
              _parseDateTime(remoteRecord['last_modified']) ?? now,
            ),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;
      case 'block_completion':
        final blockLocalId = await _resolveLocalId(
          'block',
          remoteRecord,
          'blockSupabaseId',
        );
        if (blockLocalId == null) {
          break;
        }
        await (_database.update(
          _database.blockCompletion,
        )..where((bc) => bc.id.equals(localId))).write(
          BlockCompletionCompanion(
            blockId: Value(blockLocalId),
            count: Value(remoteRecord['count'] as int),
            completedAt: Value(_parseDateTime(remoteRecord['completed_at'])!),
            lastModified: Value(
              _parseDateTime(remoteRecord['last_modified']) ?? now,
            ),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;
      case 'block_task':
        final blockLocalId = await _resolveLocalId(
          'block',
          remoteRecord,
          'blockSupabaseId',
        );
        final taskLocalId = await _resolveLocalId(
          'task',
          remoteRecord,
          'taskSupabaseId',
        );
        if (blockLocalId == null || taskLocalId == null) {
          break;
        }
        await (_database.update(_database.blockTask)..where(
              (bt) =>
                  bt.blockId.equals(blockLocalId) &
                  bt.taskId.equals(taskLocalId),
            ))
            .write(
              BlockTaskCompanion(
                lastModified: Value(
                  _parseDateTime(remoteRecord['last_modified']) ?? now,
                ),
                needsSync: const Value(false),
                isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
                version: Value(remoteRecord['version'] as int? ?? 1),
              ),
            );
        break;
      case 'settings':
        await (_database.update(
          _database.settings,
        )..where((s) => s.id.equals(localId))).write(
          SettingsCompanion(
            defaultStartTime: Value(remoteRecord['default_start_time'] as int),
            defaultTaskLength: Value(
              remoteRecord['default_task_length'] as int,
            ),
            defaultBreakTime: Value(remoteRecord['default_break_time'] as int),
            lastModified: Value(
              _parseDateTime(remoteRecord['last_modified']) ?? now,
            ),
            needsSync: const Value(false),
            isDeleted: Value(remoteRecord['is_deleted'] as bool? ?? false),
            version: Value(remoteRecord['version'] as int? ?? 1),
          ),
        );
        break;
      default:
    }
  }

  /// Delete BlockTask by supabase_id (used for pulling remote deletions)
  Future<void> _deleteBlockTaskBySupabaseId(String supabaseId) async {
    await (_database.delete(
      _database.blockTask,
    )..where((bt) => bt.supabaseId.equals(supabaseId))).go();
  }

  /// Update BlockTask supabase_id using composite key (proper way)
  Future<void> _updateBlockTaskSupabaseId(
    int blockId,
    int taskId,
    String supabaseId,
  ) async {
    final now = DateTime.now();

    await (_database.update(
          _database.blockTask,
        )..where((bt) => bt.blockId.equals(blockId) & bt.taskId.equals(taskId)))
        .write(
          BlockTaskCompanion(
            supabaseId: Value(supabaseId),
            needsSync: const Value(false),
            lastModified: Value(now),
          ),
        );
  }

  /// Safely parse DateTime from various formats
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Batch operation to handle records needing sync more efficiently
  Future<void> _batchMarkRecordsAsSynced(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    if (records.isEmpty) return;

    try {
      await _database.batch((batch) {
        for (final record in records) {
          final recordId = _getField<int>(record, 'id');
          if (recordId != null) {
            switch (tableName) {
              case 'task':
                batch.update(
                  _database.task,
                  const TaskCompanion(needsSync: Value(false)),
                  where: (t) => t.id.equals(recordId),
                );
                break;
              case 'project':
                batch.update(
                  _database.project,
                  const ProjectCompanion(needsSync: Value(false)),
                  where: (p) => p.id.equals(recordId),
                );
                break;
              case 'project_category':
                batch.update(
                  _database.projectCategory,
                  const ProjectCategoryCompanion(needsSync: Value(false)),
                  where: (pc) => pc.id.equals(recordId),
                );
                break;
              case 'block':
                batch.update(
                  _database.block,
                  const BlockCompanion(needsSync: Value(false)),
                  where: (b) => b.id.equals(recordId),
                );
                break;
              case 'task_completion':
                batch.update(
                  _database.taskCompletion,
                  const TaskCompletionCompanion(needsSync: Value(false)),
                  where: (tc) => tc.id.equals(recordId),
                );
                break;
              case 'block_completion':
                batch.update(
                  _database.blockCompletion,
                  const BlockCompletionCompanion(needsSync: Value(false)),
                  where: (bc) => bc.id.equals(recordId),
                );
                break;
              case 'block_task':
                // Handle block_task composite key using blockId and taskId
                final blockId = _getField<int>(record, 'blockId');
                final taskId = _getField<int>(record, 'taskId');
                if (blockId != null && taskId != null) {
                  batch.update(
                    _database.blockTask,
                    const BlockTaskCompanion(needsSync: Value(false)),
                    where: (bt) =>
                        bt.blockId.equals(blockId) & bt.taskId.equals(taskId),
                  );
                }
                break;
              case 'settings':
                batch.update(
                  _database.settings,
                  const SettingsCompanion(needsSync: Value(false)),
                  where: (s) => s.id.equals(recordId),
                );
                break;
            }
          }
        }
      });
    } catch (e) {
      // Fallback to individual updates
      for (final record in records) {
        final recordId = record['id'] as int?;
        if (recordId != null) {
          await _markSingleRecordAsSynced(tableName, recordId);
        }
      }
    }
  }

  Future<void> _deleteLocalRecordsByIds(
    String localTable,
    List<int> ids,
  ) async {
    switch (localTable) {
      case 'task':
        await (_database.delete(
          _database.task,
        )..where((t) => t.id.isIn(ids))).go();
        break;
      case 'project':
        await (_database.delete(
          _database.project,
        )..where((p) => p.id.isIn(ids))).go();
        break;
      case 'project_category':
        await (_database.delete(
          _database.projectCategory,
        )..where((pc) => pc.id.isIn(ids))).go();
        break;
      case 'block':
        await (_database.delete(
          _database.block,
        )..where((b) => b.id.isIn(ids))).go();
        break;
      case 'task_completion':
        await (_database.delete(
          _database.taskCompletion,
        )..where((tc) => tc.id.isIn(ids))).go();
        break;
      case 'block_completion':
        await (_database.delete(
          _database.blockCompletion,
        )..where((bc) => bc.id.isIn(ids))).go();
        break;
      case 'settings':
        await (_database.delete(
          _database.settings,
        )..where((s) => s.id.isIn(ids))).go();
        break;
      default:
    }
  }
}
