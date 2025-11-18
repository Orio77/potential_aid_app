import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/services/sync_service.dart';
import 'package:potential_aid_app/services/supabase_service.dart';

// Import other providers for invalidation (but not watch them to avoid cycles)
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/providers/project_categories_notifier.dart';
import 'package:potential_aid_app/providers/project_intervals_notifier.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/providers/tasks_notifier.dart';
import 'package:potential_aid_app/providers/task_cards_notifier.dart';
import 'package:potential_aid_app/providers/task_search_notifier.dart';
import 'package:potential_aid_app/providers/block_with_tasks_notifier.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/settings_notifier.dart';
import 'package:potential_aid_app/providers/stats_provider.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/timeline_date_notifier.dart';

// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final database = ref.watch(databaseProvider);

  // Create a callback to invalidate all data providers after sync
  void invalidateAllProviders() {
    try {
      // Import the providers we need to invalidate
      // This is safe because we're not watching them, just invalidating them

      // Projects and related data
      ref.invalidate(projectsNotifierProvider);
      ref.invalidate(projectProvider);
      ref.invalidate(projectByBlockProvider);
      ref.invalidate(descendantProjectProvider);
      ref.invalidate(projectTimeLineProvider);
      ref.invalidate(projectIntervalsNotifierProvider);
      ref.invalidate(individualProjectProvider);

      // Project categories
      ref.invalidate(projectCategoriesProvider);
      ref.invalidate(projectCategoryByIdProvider);
      ref.invalidate(projectCategoryByProjectIdProvider);

      // Tasks
      ref.invalidate(tasksNotifierProvider);
      ref.invalidate(taskCardsNotifierProvider);
      ref.invalidate(taskSearchProvider);
      ref.invalidate(projectTasksNotifier);

      // Schedule and blocks
      ref.invalidate(scheduleNotifierProvider);
      ref.invalidate(blockTasksNotifier);

      // Completion and stats
      ref.invalidate(blockCompletionPercentageProvider);
      ref.invalidate(scheduleDayCompletionPercentagesProvider);
      ref.invalidate(completionChangeNotifierProvider);
      ref.invalidate(projectStatsNotifier);
      ref.invalidate(taskCompletionMonthlyNotifier);
      ref.invalidate(blockCompletionMonthlyNotifier);

      // Settings
      ref.invalidate(settingsNotifierProvider);

      // Date/Timeline providers (these may not change but invalidating for consistency)
      ref.invalidate(dateNotifierProvider);
      ref.invalidate(dateTimeNotifierProvider);
      ref.invalidate(timelineDateNotifierProvider);

      // Note: Sync-related providers will auto-update when needed
      // We don't invalidate them here to avoid circular dependencies

      print('🔄 All providers invalidated after sync');
    } catch (e) {
      print('⚠️ Error invalidating providers: $e');
    }
  }

  final syncService = SyncService(
    database,
    onSyncComplete: invalidateAllProviders,
  );

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
