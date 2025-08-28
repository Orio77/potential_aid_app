import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/data/daos/database_completions.dart';

// Provider that gets completion percentage for a specific block
final blockCompletionProvider = FutureProvider.family<double, int>((
  ref,
  blockId,
) async {
  final database = ref.read(databaseProvider);
  final percentage = await database.getBlockCompletionPercentage(blockId);
  return percentage;
});

// Provider that watches for completion changes across all blocks
// This will be used to invalidate specific block completion providers when completion changes
final completionChangeNotifierProvider =
    StateNotifierProvider<CompletionChangeNotifier, int>((ref) {
      return CompletionChangeNotifier();
    });

class CompletionChangeNotifier extends StateNotifier<int> {
  CompletionChangeNotifier() : super(0);

  // Call this whenever completion data changes
  void notifyCompletionChanged() {
    state = state + 1; // Increment to trigger listeners
  }
}
