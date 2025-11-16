import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/services/sync_service.dart';
import 'package:potential_aid_app/services/supabase_service.dart';

// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final database = ref.watch(databaseProvider);
  final syncService = SyncService(database);

  // Ensure the sync service is initialized
  syncService.initialize().catchError((e) {
    print('Failed to initialize sync service: $e');
  });

  ref.onDispose(syncService.dispose);
  return syncService;
});

// Current Sync Status Provider - Stream-based
final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final syncService = ref.read(syncServiceProvider);
  return syncService.statusStream.handleError((error) {
    print('Sync status stream error: $error');
    return SyncStatus.error;
  });
});

// Last Sync Result Provider - Stream-based
final lastSyncResultProvider = StreamProvider<SyncResult?>((ref) {
  final syncService = ref.read(syncServiceProvider);
  return syncService.resultStream.handleError((error) {
    print('Sync result stream error: $error');
    return null;
  });
});

// Pending Sync Count Provider
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  return syncService.getPendingSyncCount();
});

// Sync Needed Provider
final syncNeededProvider = FutureProvider<bool>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  return syncService.needsSync();
});

// Connectivity Status Provider
final connectivityProvider = FutureProvider<bool>((ref) async {
  final supabaseService = SupabaseService.instance;
  return supabaseService.hasInternetConnection();
});

// Last Sync Time Provider
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final syncService = ref.read(syncServiceProvider);
  return syncService.lastSyncTime;
});

// Sync Action Provider (for triggering sync) - auto dispose to prevent memory leaks
final syncActionProvider = FutureProvider.family
    .autoDispose<SyncResult, SyncDirection>((ref, direction) async {
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.sync(direction: direction);

      // Only refresh dependent providers after successful sync - do it outside the provider
      if (result.success) {
        // Schedule for next event loop to avoid circular dependencies
        Future.microtask(() {
          try {
            // Check if provider is still alive before invalidation
            ref.invalidate(pendingSyncCountProvider);
            ref.invalidate(syncNeededProvider);
          } catch (e) {
            // Silently catch errors during provider invalidation
            print('Provider invalidation after sync: $e');
          }
        });
      }

      return result;
    });

// Simple sync status display provider - no circular dependencies
final syncStatusDisplayProvider =
    Provider<({String text, bool isError, bool isSuccess})>((ref) {
      final statusAsync = ref.watch(syncStatusProvider);
      final lastResultAsync = ref.watch(lastSyncResultProvider);

      return statusAsync.when(
        data: (status) {
          switch (status) {
            case SyncStatus.idle:
              // Check last sync result for idle state display
              return lastResultAsync.when(
                data: (lastResult) {
                  if (lastResult?.success == true) {
                    return (text: 'Synced', isError: false, isSuccess: true);
                  } else if (lastResult?.success == false) {
                    return (
                      text: 'Sync Failed',
                      isError: true,
                      isSuccess: false,
                    );
                  }
                  return (text: 'Ready', isError: false, isSuccess: false);
                },
                loading: () =>
                    (text: 'Ready', isError: false, isSuccess: false),
                error: (_, __) =>
                    (text: 'Ready', isError: false, isSuccess: false),
              );
            case SyncStatus.syncing:
              return (text: 'Syncing...', isError: false, isSuccess: false);
            case SyncStatus.success:
              return (text: 'Sync Complete', isError: false, isSuccess: true);
            case SyncStatus.error:
              return (text: 'Sync Error', isError: true, isSuccess: false);
            case SyncStatus.offline:
              return (text: 'Offline', isError: true, isSuccess: false);
          }
        },
        loading: () => (text: 'Loading...', isError: false, isSuccess: false),
        error: (_, __) => (text: 'Error', isError: true, isSuccess: false),
      );
    });
