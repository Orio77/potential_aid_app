/// Data models for sync functionality

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
