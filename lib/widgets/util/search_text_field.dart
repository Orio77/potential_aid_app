import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin SearchCapability<T> on StateNotifier<List<T>> {
  Future<void> search(String query, List<bool Function(T)>? predicates);
}

class SearchTextField<T, N extends StateNotifier<List<T>>>
    extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String labelText;
  final String? Function(String?)? validator;
  final AutoDisposeStateNotifierProvider<N, List<T>> searchProvider;
  final String Function(T) getDisplayText;
  final void Function(T)? onItemSelected;
  final Widget Function(T)? leadingIcon;
  final Widget? trailingIcon;
  final int? maxResults;
  final bool enabled;
  final void Function(String)? onChanged;
  final List<bool Function(T)>? predicates;
  final InputDecoration? textFieldDecoration;
  final void Function(String)? onFieldSubmitted;

  const SearchTextField({
    super.key,
    this.controller,
    this.focusNode,
    required this.labelText,
    this.validator,
    required this.searchProvider,
    required this.getDisplayText,
    this.onItemSelected,
    this.leadingIcon,
    this.trailingIcon,
    this.maxResults,
    this.enabled = true,
    this.onChanged,
    this.predicates,
    this.textFieldDecoration,
    this.onFieldSubmitted,
  });

  @override
  ConsumerState<SearchTextField<T, N>> createState() =>
      _SearchTextFieldState<T, N>();
}

class _SearchTextFieldState<T, N extends StateNotifier<List<T>>>
    extends ConsumerState<SearchTextField<T, N>> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showSuggestions = _focusNode.hasFocus && _controller.text.isNotEmpty;
        });
      }
    });
  }

  void _onTextChanged(String value) {
    (ref.read(widget.searchProvider.notifier) as dynamic).search(
      value,
      widget.predicates,
    );

    widget.onChanged?.call(value);

    setState(() {
      _showSuggestions = _focusNode.hasFocus && value.isNotEmpty;
    });
  }

  void _onItemSelected(T item) {
    final text = widget.getDisplayText(item);

    _controller
      ..text = text
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );

    widget.onItemSelected?.call(item);

    _onTextChanged(text);
    setState(() {
      _showSuggestions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(widget.searchProvider);
    final limitedResults = (widget.maxResults != null)
        ? searchResults.take(widget.maxResults!).toList()
        : searchResults.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: widget.enabled
                        ? () {
                            _controller.clear();
                            _onTextChanged('');
                          }
                        : null,
                  )
                : null,
          ),
          validator: widget.validator,
          enabled: widget.enabled,
          onChanged: _onTextChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
        ),

        if (_showSuggestions && limitedResults.isNotEmpty) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).cardColor,
              ),
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final item = limitedResults[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        widget.getDisplayText(item),
                        style: const TextStyle(fontSize: 14),
                      ),
                      leading: widget.leadingIcon?.call(item),
                      trailing: widget.trailingIcon,
                      onTap: () => _onItemSelected(item),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemCount: limitedResults.length,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
