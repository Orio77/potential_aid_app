import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/claude/models/claude_suggestion.dart';
import 'package:potential_aid_app/claude/services/claude_suggestions_service.dart';
import 'package:potential_aid_app/providers/database_provider.dart';

final claudeSuggestionsServiceProvider = Provider<ClaudeSuggestionsService>((ref) {
  final db = ref.watch(databaseProvider);
  return ClaudeSuggestionsService(db);
});

/// Fetches the current list of pending suggestions from Supabase.
final pendingSuggestionsProvider =
    FutureProvider<List<ClaudeSuggestion>>((ref) async {
  final service = ref.watch(claudeSuggestionsServiceProvider);
  return service.fetchPending();
});
