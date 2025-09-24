import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/daos/database_completions.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/data/tables/block.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

final blockCompletionPercentageProvider = FutureProvider.family<double?, int>((
  ref,
  int blockId,
) async {
  final database = ref.read(databaseProvider);

  try {
    final percentage = await database.getBlockCompletionPercentage(blockId);
    return percentage;
  } catch (e) {
    rethrow;
  }
});

final scheduleDayCompletionPercentagesProvider =
    FutureProvider.family<double, DateTime>((ref, DateTime dateParam) async {
      final database = ref.read(databaseProvider);

      print('DEBUG: dateParam = $dateParam');

      // Fetch data concurrently for better performance
      final results = await Future.wait([
        database.blockDao.getBlocksWithTasks(dateParam),
        database.blockDao.getBlockCompletionsForDate(dateParam),
        database.taskDao.getTaskCompletionsForDate(dateParam),
      ]);

      final blocksWithTasks = results[0] as List<BlockWithTasks>;
      final blockCompletions = results[1] as List<BlockCompletionData>;
      final taskCompletions = results[2] as List<TaskCompletionData>;

      print(blocksWithTasks.length);
      print(blockCompletions.length);
      print(taskCompletions.length);

      if (blocksWithTasks.isEmpty) {
        print("empty");
        return 0.0; // No blocks scheduled, return 0%
      }

      // Create lookup maps for O(1) access
      final blockCompletionMap = <int, int>{
        for (var bc in blockCompletions) bc.blockId: bc.count,
      };

      // Sum up task completions by task ID
      final taskCompletionMap = <int, int>{};
      for (var tc in taskCompletions) {
        taskCompletionMap[tc.taskId] =
            (taskCompletionMap[tc.taskId] ?? 0) + tc.count;
      }

      double totalCompletedMinutes = 0;
      double totalPlannedMinutes = 0;

      for (final blockWithTasks in blocksWithTasks) {
        final blockId = blockWithTasks.block.id;
        final blockLength = blockWithTasks.block.lengthMinutes;

        totalPlannedMinutes += blockLength;

        if (blockWithTasks.tasks == null || blockWithTasks.tasks!.isEmpty) {
          // Block without tasks - use block completion data
          totalCompletedMinutes += blockCompletionMap[blockId] ?? 0;
        } else {
          // Block with tasks - check if all tasks are completed
          bool allTasksCompleted = true;
          for (final task in blockWithTasks.tasks!) {
            // Calculate total progress: existing progress + today's completions
            final todaysCompletions = taskCompletionMap[task.id] ?? 0;
            final totalProgress = task.current + todaysCompletions;

            if (totalProgress < task.endGoal) {
              allTasksCompleted = false;
              break; // Early exit if any task is incomplete
            }
          }

          if (allTasksCompleted) {
            // All tasks completed - credit the full block length
            totalCompletedMinutes += blockLength;
            print(allTasksCompleted);
          } else {
            // Partial completion - use block completion data as fallback
            totalCompletedMinutes += blockCompletionMap[blockId] ?? 0;
          }
        }
        print(
          "${blockWithTasks.block.projectId}, block length: $blockLength, completed minutes: $totalCompletedMinutes, planned minutes: $totalPlannedMinutes",
        );
      }

      print(totalCompletedMinutes);
      print(totalPlannedMinutes);

      if (totalPlannedMinutes == 0) {
        return 0.0;
      }

      return (totalCompletedMinutes / totalPlannedMinutes).clamp(0.0, 1.0);
    });

class CompletionChangeNotifier extends StateNotifier<int> {
  CompletionChangeNotifier() : super(0);

  void notifyCompletionChanged() {
    state = state + 1;
  }
}

final completionChangeNotifierProvider =
    StateNotifierProvider<CompletionChangeNotifier, int>((ref) {
      return CompletionChangeNotifier();
    });
