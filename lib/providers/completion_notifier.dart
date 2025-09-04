import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/daos/database_completions.dart';
import 'package:potential_aid_app/data/database.dart';
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
    FutureProvider.family<Map<BlockData, BlockCompletionData>, DateTime>((
      ref,
      DateTime date,
    ) async {
      final database = ref.read(databaseProvider);

      return await database.blockDao.getBlockCompletionsForDate(date);
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
