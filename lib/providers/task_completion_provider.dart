import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

// Data models for heatmap
class HeatmapData {
  final DateTime date;
  final int totalCompletions;
  final Map<int, int> taskBreakdown; // taskId -> count

  const HeatmapData({
    required this.date,
    required this.totalCompletions,
    required this.taskBreakdown,
  });
}

class HeatmapParams {
  final DateTime startDate;
  final DateTime endDate;
  final List<int>? taskIds; // null for all tasks
  final int? projectId; // filter by project

  const HeatmapParams({
    required this.startDate,
    required this.endDate,
    this.taskIds,
    this.projectId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapParams &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          _listEquals(taskIds, other.taskIds) &&
          projectId == other.projectId;

  @override
  int get hashCode => Object.hash(startDate, endDate, taskIds, projectId);

  bool _listEquals(List<int>? a, List<int>? b) {
    if (a?.length != b?.length) return false;
    if (a != null && b != null) {
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
    }
    return true;
  }
}

// Repository for data access
class TaskCompletionRepository {
  final AppDatabase _db;

  TaskCompletionRepository(this._db);

  Future<List<HeatmapData>> getHeatmapData(HeatmapParams params) async {
    // Use aggregated query for performance
    final query = _db.select(_db.taskCompletion).join([
      leftOuterJoin(_db.task, _db.task.id.equalsExp(_db.taskCompletion.taskId)),
    ]);

    query.where(
      _db.taskCompletion.completedAt.isBetweenValues(
        params.startDate,
        params.endDate,
      ),
    );

    if (params.taskIds != null && params.taskIds!.isNotEmpty) {
      query.where(_db.taskCompletion.taskId.isIn(params.taskIds!));
    }

    if (params.projectId != null) {
      query.where(_db.task.projectId.equals(params.projectId!));
    }

    final results = await query.get();

    // Group by date and aggregate
    final Map<DateTime, Map<int, int>> dailyData = {};

    for (final row in results) {
      final completion = row.readTable(_db.taskCompletion);
      final date = DateTime(
        completion.completedAt.year,
        completion.completedAt.month,
        completion.completedAt.day,
      );

      dailyData.putIfAbsent(date, () => {});
      dailyData[date]![completion.taskId] =
          (dailyData[date]![completion.taskId] ?? 0) + completion.count;
    }

    // Convert to HeatmapData list
    return dailyData.entries.map((entry) {
      final totalCompletions = entry.value.values.fold(0, (a, b) => a + b);
      return HeatmapData(
        date: entry.key,
        totalCompletions: totalCompletions,
        taskBreakdown: entry.value,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Stream<List<HeatmapData>> watchHeatmapData(HeatmapParams params) {
    // Watch task_completion table for changes
    return _db.select(_db.taskCompletion).watch().asyncMap((_) async {
      final result = await getHeatmapData(params);

      return result;
    });
  }
}

// Providers
final taskCompletionRepositoryProvider = Provider<TaskCompletionRepository>((
  ref,
) {
  final database = ref.watch(databaseProvider);
  return TaskCompletionRepository(database);
});

final heatmapDataProvider =
    FutureProvider.family<List<HeatmapData>, HeatmapParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(taskCompletionRepositoryProvider);
      return repository.getHeatmapData(params);
    });

final heatmapDataStreamProvider =
    StreamProvider.family<List<HeatmapData>, HeatmapParams>((ref, params) {
      final repository = ref.watch(taskCompletionRepositoryProvider);
      return repository.watchHeatmapData(params);
    });

// Convenience providers for common date ranges
final yearlyHeatmapProvider = FutureProvider.family<List<HeatmapData>, int>((
  ref,
  year,
) {
  final params = HeatmapParams(
    startDate: DateTime(year, 1, 1),
    endDate: DateTime(year, 12, 31, 23, 59, 59),
  );
  return ref.watch(heatmapDataProvider(params).future);
});

final monthlyHeatmapProvider =
    FutureProvider.family<List<HeatmapData>, ({int year, int month})>((
      ref,
      params,
    ) {
      final startDate = DateTime(params.year, params.month, 1);
      final endDate = DateTime(params.year, params.month + 1, 0, 23, 59, 59);

      final heatmapParams = HeatmapParams(
        startDate: startDate,
        endDate: endDate,
      );
      return ref.watch(heatmapDataProvider(heatmapParams).future);
    });

// Project-specific heatmap provider
final projectHeatmapProvider =
    FutureProvider.family<List<HeatmapData>, ({int projectId, int year})>((
      ref,
      params,
    ) {
      final heatmapParams = HeatmapParams(
        startDate: DateTime(params.year, 1, 1),
        endDate: DateTime(params.year, 12, 31, 23, 59, 59),
        projectId: params.projectId,
      );
      return ref.watch(heatmapDataProvider(heatmapParams).future);
    });
