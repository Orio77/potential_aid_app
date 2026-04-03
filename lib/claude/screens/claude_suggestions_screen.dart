import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/claude/models/claude_suggestion.dart';
import 'package:potential_aid_app/claude/providers/claude_suggestions_provider.dart';

class ClaudeSuggestionsScreen extends ConsumerWidget {
  const ClaudeSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(pendingSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude Suggestions'),
        centerTitle: true,
        actions: [
          suggestionsAsync.whenData((list) => list).valueOrNull?.isNotEmpty == true
              ? TextButton.icon(
                  onPressed: () => _acceptAll(context, ref,
                      suggestionsAsync.valueOrNull ?? []),
                  icon: const Icon(Icons.done_all),
                  label: const Text('Accept all'),
                )
              : const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(pendingSuggestionsProvider),
          ),
        ],
      ),
      body: suggestionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load suggestions:\n$e',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(pendingSuggestionsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (suggestions) {
          if (suggestions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 56, color: Colors.green),
                  SizedBox(height: 12),
                  Text('No pending suggestions',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: suggestions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _SuggestionCard(suggestion: suggestions[i]),
          );
        },
      ),
    );
  }

  Future<void> _acceptAll(
    BuildContext context,
    WidgetRef ref,
    List<ClaudeSuggestion> suggestions,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept all suggestions?'),
        content: Text(
            'This will apply ${suggestions.length} change(s) to your data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Accept all')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final service = ref.read(claudeSuggestionsServiceProvider);
    for (final s in suggestions) {
      await service.accept(s);
    }
    ref.invalidate(pendingSuggestionsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied ${suggestions.length} suggestion(s)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// ── Single suggestion card ────────────────────────────────────────────────────

class _SuggestionCard extends ConsumerStatefulWidget {
  final ClaudeSuggestion suggestion;
  const _SuggestionCard({required this.suggestion});

  @override
  ConsumerState<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends ConsumerState<_SuggestionCard> {
  bool _busy = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    final cs = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${s.tableName} · ${s.operation}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.description,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Reasoning (collapsible)
          if (s.reasoning != null) ...[
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded ? 'Hide reasoning' : 'Show reasoning',
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  s.reasoning!,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade700, height: 1.5),
                ),
              ),
          ],

          // Payload preview
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: _PayloadTable(payload: s.payload),
          ),

          const Divider(height: 1),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : () => _reject(s),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _busy ? null : () => _accept(s),
                  icon: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Accept'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _accept(ClaudeSuggestion s) async {
    setState(() => _busy = true);
    try {
      await ref.read(claudeSuggestionsServiceProvider).accept(s);
      ref.invalidate(pendingSuggestionsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Change applied'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reject(ClaudeSuggestion s) async {
    setState(() => _busy = true);
    try {
      await ref.read(claudeSuggestionsServiceProvider).reject(s.id);
      ref.invalidate(pendingSuggestionsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _busy = false);
      }
    }
  }
}

// ── Payload key-value table ───────────────────────────────────────────────────

class _PayloadTable extends StatelessWidget {
  final Map<String, dynamic> payload;
  const _PayloadTable({required this.payload});

  @override
  Widget build(BuildContext context) {
    final entries = payload.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: entries.map((e) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
              child: Text(
                e.key,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Text(
                '${e.value}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
