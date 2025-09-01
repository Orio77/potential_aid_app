import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/data/daos/database_completions.dart';

final blockCompletionProvider = FutureProvider.family<double?, int>((
  ref,
  blockId,
) async {
  print('blockCompletionProvider: called for blockId $blockId');
  final database = ref.read(databaseProvider);
  print('blockCompletionProvider: database obtained');

  try {
    final percentage = await database.getBlockCompletionPercentage(blockId);
    print('blockCompletionProvider: percentage = $percentage');
    return percentage;
  } catch (e, stackTrace) {
    print('blockCompletionProvider: ERROR - $e');
    print('blockCompletionProvider: STACK TRACE - $stackTrace');
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
