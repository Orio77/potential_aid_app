import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/sync_providers.dart';
import 'package:potential_aid_app/services/sync_service.dart';

class SyncButton extends ConsumerWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the dedicated display provider to avoid circular dependencies
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final displayInfo = ref.watch(syncStatusDisplayProvider);

    return syncStatusAsync.when(
      data: (syncStatus) {
        return PopupMenuButton<SyncDirection>(
          key: ValueKey(
            'sync-button-$syncStatus',
          ), // Add key for better performance
          icon: _buildSyncIcon(syncStatus, displayInfo),
          tooltip: displayInfo.text,
          onSelected: (direction) => _performSync(ref, direction, context),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: SyncDirection.bidirectional,
              child: ListTile(
                leading: Icon(Icons.sync),
                title: Text('Full Sync'),
                subtitle: Text('Push and pull changes'),
              ),
            ),
            const PopupMenuItem(
              value: SyncDirection.push,
              child: ListTile(
                leading: Icon(Icons.cloud_upload),
                title: Text('Push to Cloud'),
                subtitle: Text('Upload local changes'),
              ),
            ),
            const PopupMenuItem(
              value: SyncDirection.pull,
              child: ListTile(
                leading: Icon(Icons.cloud_download),
                title: Text('Pull from Cloud'),
                subtitle: Text('Download remote changes'),
              ),
            ),
          ],
        );
      },
      loading: () => PopupMenuButton<SyncDirection>(
        icon: _buildSyncIcon(SyncStatus.syncing, displayInfo),
        tooltip: 'Loading sync status...',
        onSelected: (direction) => _performSync(ref, direction, context),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: SyncDirection.bidirectional,
            child: ListTile(
              leading: Icon(Icons.sync),
              title: Text('Full Sync'),
              subtitle: Text('Push and pull changes'),
            ),
          ),
          const PopupMenuItem(
            value: SyncDirection.push,
            child: ListTile(
              leading: Icon(Icons.cloud_upload),
              title: Text('Push to Cloud'),
              subtitle: Text('Upload local changes'),
            ),
          ),
          const PopupMenuItem(
            value: SyncDirection.pull,
            child: ListTile(
              leading: Icon(Icons.cloud_download),
              title: Text('Pull from Cloud'),
              subtitle: Text('Download remote changes'),
            ),
          ),
        ],
      ),
      error: (error, stackTrace) => PopupMenuButton<SyncDirection>(
        icon: _buildSyncIcon(SyncStatus.error, displayInfo),
        tooltip: 'Sync error: $error',
        onSelected: (direction) => _performSync(ref, direction, context),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: SyncDirection.bidirectional,
            child: ListTile(
              leading: Icon(Icons.sync),
              title: Text('Full Sync'),
              subtitle: Text('Push and pull changes'),
            ),
          ),
          const PopupMenuItem(
            value: SyncDirection.push,
            child: ListTile(
              leading: Icon(Icons.cloud_upload),
              title: Text('Push to Cloud'),
              subtitle: Text('Upload local changes'),
            ),
          ),
          const PopupMenuItem(
            value: SyncDirection.pull,
            child: ListTile(
              leading: Icon(Icons.cloud_download),
              title: Text('Pull from Cloud'),
              subtitle: Text('Download remote changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIcon(
    SyncStatus status,
    ({String text, bool isError, bool isSuccess}) display,
  ) {
    IconData iconData;
    Color? color;

    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SyncStatus.success:
        iconData = Icons.cloud_done;
        color = Colors.green;
        break;
      case SyncStatus.error:
        iconData = Icons.cloud_off;
        color = Colors.red;
        break;
      case SyncStatus.offline:
        iconData = Icons.wifi_off;
        color = Colors.orange;
        break;
      default:
        iconData = Icons.cloud_sync;
        color = display.isSuccess
            ? Colors.green
            : display.isError
            ? Colors.red
            : null;
    }

    return Icon(iconData, color: color);
  }

  Future<void> _performSync(
    WidgetRef ref,
    SyncDirection direction,
    BuildContext context,
  ) async {
    try {
      // Show snackbar for sync start
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_getSyncStartMessage(direction)),
          duration: const Duration(seconds: 2),
        ),
      );

      // Trigger sync
      final syncResultAsync = ref.read(syncActionProvider(direction).future);
      final result = await syncResultAsync;

      // Show result
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Sync completed: ${result.recordsSynced} records'
                : 'Sync failed: ${result.error}',
          ),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: Duration(seconds: result.success ? 3 : 5),
          action: result.success
              ? null
              : SnackBarAction(
                  label: 'Details',
                  onPressed: () => _showSyncError(context, result),
                ),
        ),
      );
    } catch (e) {
      // Handle sync error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _getSyncStartMessage(SyncDirection direction) {
    switch (direction) {
      case SyncDirection.bidirectional:
        return 'Starting full sync...';
      case SyncDirection.push:
        return 'Uploading local changes...';
      case SyncDirection.pull:
        return 'Downloading remote changes...';
    }
  }

  void _showSyncError(BuildContext context, SyncResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error: ${result.error}'),
            const SizedBox(height: 8),
            Text('Time: ${result.timestamp}'),
            if (result.tableStats.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Table Statistics:'),
              ...result.tableStats.entries.map(
                (e) => Text('${e.key}: ${e.value} records'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
