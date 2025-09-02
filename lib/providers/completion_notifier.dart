import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/data/daos/database_completions.dart';

final blockCompletionProvider = FutureProvider.family<double?, int>((
  ref,
  blockId,
) async {
  final database = ref.read(databaseProvider);

  try {
    final percentage = await database.getBlockCompletionPercentage(blockId);
    return percentage;
  } catch (e) {
    rethrow;
  }
});

final completionChangeNotifierProvider =
    StateNotifierProvider<CompletionChangeNotifier, int>((ref) {
      return CompletionChangeNotifier();
    });

class CompletionChangeNotifier extends StateNotifier<int> {
  CompletionChangeNotifier() : super(0);

  void notifyCompletionChanged() {
    state = state + 1;
  }
}
