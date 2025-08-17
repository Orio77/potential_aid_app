import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchSuggestionsWidget<T> extends ConsumerWidget {
  final AutoDisposeStateNotifierProvider<StateNotifier<List<T>>, List<T>>
  searchProvider;
  final String Function(T) getDisplayText;
  final void Function(T) onItemSelected;
  final Widget Function(T)? leadingIcon;
  final Widget? trailingIcon;
  final bool showSuggestions;
  final int maxResults;

  const SearchSuggestionsWidget({
    super.key,
    required this.searchProvider,
    required this.getDisplayText,
    required this.onItemSelected,
    required this.showSuggestions,
    this.leadingIcon,
    this.trailingIcon,
    this.maxResults = 3,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchProvider);
    final limitedResults = searchResults.take(maxResults).toList();

    if (!showSuggestions || searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final item = limitedResults[index];
              return ListTile(
                dense: true,
                title: Text(
                  getDisplayText(item),
                  style: const TextStyle(fontSize: 14),
                ),
                leading: leadingIcon?.call(item),
                trailing: trailingIcon,
                onTap: () => onItemSelected(item),
              );
            },
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemCount: limitedResults.length,
          ),
        ),
      ],
    );
  }
}
