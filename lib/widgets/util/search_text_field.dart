import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin SearchCapability<T> on StateNotifier<List<T>> {
  Future<void> search(String query, List<bool Function(T)>? predicates);
}

class _SearchHighlightDownIntent extends Intent {
  const _SearchHighlightDownIntent();
}

class _SearchHighlightUpIntent extends Intent {
  const _SearchHighlightUpIntent();
}

class _SearchSelectIntent extends Intent {
  const _SearchSelectIntent();
}

class _SearchDismissIntent extends Intent {
  const _SearchDismissIntent();
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
  final ScrollController _suggestionsScrollController = ScrollController();
  final LayerLink _fieldLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  final GlobalKey _fieldKey = GlobalKey();
  double _fieldWidth = 0;

  /// Pointer is over the suggestion panel (or moving to it).
  bool _cursorOverSuggestions = false;
  /// After choosing a row; cleared when the user edits the query.
  bool _suppressAfterPick = false;
  /// Tap outside this field+list or Escape; cleared on refocus or when typing.
  bool _dismissedByOutside = false;
  Timer? _clearCursorExitTimer;
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _clearCursorExitTimer?.cancel();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    _suggestionsScrollController.dispose();
    super.dispose();
  }

  void _syncOverlayVisibility(bool shouldShow) {
    if (shouldShow && !_overlayController.isShowing) {
      _overlayController.show();
    } else if (!shouldShow && _overlayController.isShowing) {
      _overlayController.hide();
    }
  }

  void _updateFieldWidth() {
    final ctx = _fieldKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final width = box.size.width;
    if (width != _fieldWidth) {
      _fieldWidth = width;
    }
  }

  void _onFocusChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        if (_focusNode.hasFocus) {
          _dismissedByOutside = false;
        }
      });
    });
  }

  void _scheduleCursorLeavePanel() {
    _clearCursorExitTimer?.cancel();
    _clearCursorExitTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _cursorOverSuggestions = false);
    });
  }

  void _runSearch(String value) {
    (ref.read(widget.searchProvider.notifier) as dynamic).search(
      value,
      widget.predicates,
    );
  }

  bool _shouldShowSuggestions(List<T> limitedResults) {
    if (!widget.enabled) return false;
    if (_suppressAfterPick) return false;
    if (_dismissedByOutside) return false;
    if (_controller.text.isEmpty) return false;
    if (limitedResults.isEmpty) return false;
    return _focusNode.hasFocus || _cursorOverSuggestions;
  }

  void _scrollHighlightIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_suggestionsScrollController.hasClients) return;
      const approxRowHeight = 52.0;
      final position = _suggestionsScrollController.position;
      final targetOffset = (_highlightedIndex * approxRowHeight).clamp(
        0.0,
        position.maxScrollExtent,
      );
      _suggestionsScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onTextChanged(
    String value, {
    bool allowSuggestions = true,
  }) {
    _runSearch(value);

    widget.onChanged?.call(value);

    setState(() {
      if (allowSuggestions) {
        _suppressAfterPick = false;
        _dismissedByOutside = false;
      }
      _highlightedIndex = 0;
    });
  }

  void _onFieldSubmitted(String value) {
    final searchResults = ref.read(widget.searchProvider);
    final limited = (widget.maxResults != null)
        ? searchResults.take(widget.maxResults!).toList()
        : searchResults.toList();

    if (_shouldShowSuggestions(limited) &&
        limited.isNotEmpty &&
        _highlightedIndex < limited.length) {
      _onItemSelected(limited[_highlightedIndex]);
      return;
    }
    widget.onFieldSubmitted?.call(value);
  }

  void _onItemSelected(T item) {
    final text = widget.getDisplayText(item);

    _controller
      ..text = text
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );

    widget.onItemSelected?.call(item);

    _runSearch(text);
    widget.onChanged?.call(text);

    setState(() {
      _suppressAfterPick = true;
      _dismissedByOutside = false;
      _cursorOverSuggestions = false;
      _highlightedIndex = 0;
    });
  }

  void _moveHighlight(int delta, int resultCount) {
    if (resultCount == 0) return;
    setState(() {
      _highlightedIndex = (_highlightedIndex + delta).clamp(0, resultCount - 1);
    });
    _scrollHighlightIntoView();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(widget.searchProvider, (previous, next) {
      final limited = (widget.maxResults != null)
          ? next.take(widget.maxResults!).toList()
          : next.toList();
      if (limited.isEmpty) {
        if (_highlightedIndex != 0) {
          setState(() => _highlightedIndex = 0);
        }
      } else if (_highlightedIndex >= limited.length) {
        setState(() => _highlightedIndex = limited.length - 1);
      }
    });

    final searchResults = ref.watch(widget.searchProvider);
    final limitedResults = (widget.maxResults != null)
        ? searchResults.take(widget.maxResults!).toList()
        : searchResults.toList();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final suggestionsOpen = _shouldShowSuggestions(limitedResults);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateFieldWidth();
      _syncOverlayVisibility(suggestionsOpen);
    });

    final Map<ShortcutActivator, Intent> shortcuts = {};
    if (suggestionsOpen) {
      shortcuts[const SingleActivator(LogicalKeyboardKey.arrowDown)] =
          const _SearchHighlightDownIntent();
      shortcuts[const SingleActivator(LogicalKeyboardKey.arrowUp)] =
          const _SearchHighlightUpIntent();
      shortcuts[const SingleActivator(LogicalKeyboardKey.enter)] =
          const _SearchSelectIntent();
      shortcuts[const SingleActivator(LogicalKeyboardKey.numpadEnter)] =
          const _SearchSelectIntent();
      shortcuts[const SingleActivator(LogicalKeyboardKey.escape)] =
          const _SearchDismissIntent();
    }

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          _SearchHighlightDownIntent: CallbackAction<_SearchHighlightDownIntent>(
            onInvoke: (_) {
              _moveHighlight(1, limitedResults.length);
              return null;
            },
          ),
          _SearchHighlightUpIntent: CallbackAction<_SearchHighlightUpIntent>(
            onInvoke: (_) {
              _moveHighlight(-1, limitedResults.length);
              return null;
            },
          ),
          _SearchSelectIntent: CallbackAction<_SearchSelectIntent>(
            onInvoke: (_) {
              if (limitedResults.isNotEmpty &&
                  _highlightedIndex < limitedResults.length) {
                _onItemSelected(limitedResults[_highlightedIndex]);
              }
              return null;
            },
          ),
          _SearchDismissIntent: CallbackAction<_SearchDismissIntent>(
            onInvoke: (_) {
              setState(() {
                _dismissedByOutside = true;
                _cursorOverSuggestions = false;
                _highlightedIndex = 0;
              });
              return null;
            },
          ),
        },
        child: TapRegion(
          groupId: _fieldLink,
          onTapOutside: (_) {
            setState(() {
              _dismissedByOutside = true;
              _cursorOverSuggestions = false;
            });
          },
          child: CompositedTransformTarget(
            link: _fieldLink,
            child: OverlayPortal(
              controller: _overlayController,
              overlayChildBuilder: (overlayContext) {
                return Positioned(
                  width: _fieldWidth > 0 ? _fieldWidth : null,
                  child: CompositedTransformFollower(
                    link: _fieldLink,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.bottomLeft,
                    followerAnchor: Alignment.topLeft,
                    offset: const Offset(0, 4),
                    child: _buildSuggestionsPanel(
                      theme,
                      cs,
                      limitedResults,
                    ),
                  ),
                );
              },
              child: Container(
                key: _fieldKey,
                child: TextFormField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration:
                      (widget.textFieldDecoration ?? const InputDecoration())
                          .copyWith(
                    labelText: widget.labelText,
                    border: widget.textFieldDecoration?.border ??
                        const OutlineInputBorder(),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: widget.enabled
                                ? () {
                                    setState(() {
                                      _suppressAfterPick = false;
                                      _dismissedByOutside = false;
                                      _cursorOverSuggestions = false;
                                    });
                                    _controller.clear();
                                    _onTextChanged('');
                                  }
                                : null,
                          )
                        : widget.textFieldDecoration?.suffixIcon,
                  ),
                  validator: widget.validator,
                  enabled: widget.enabled,
                  maxLines: 1,
                  textInputAction: TextInputAction.search,
                  onChanged: _onTextChanged,
                  onFieldSubmitted: _onFieldSubmitted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsPanel(
    ThemeData theme,
    ColorScheme cs,
    List<T> limitedResults,
  ) {
    return TapRegion(
      groupId: _fieldLink,
      onTapOutside: (_) {
        setState(() {
          _dismissedByOutside = true;
          _cursorOverSuggestions = false;
        });
      },
      child: MouseRegion(
        onEnter: (_) {
          _clearCursorExitTimer?.cancel();
          setState(() => _cursorOverSuggestions = true);
        },
        onExit: (_) {
          _scheduleCursorLeavePanel();
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            _clearCursorExitTimer?.cancel();
            setState(() => _cursorOverSuggestions = true);
            if (widget.enabled && _focusNode.canRequestFocus) {
              _focusNode.requestFocus();
            }
          },
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                color: theme.cardColor,
              ),
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                descendantsAreFocusable: false,
                child: SizedBox(
                  height: 120,
                  child: ListView.separated(
                    controller: _suggestionsScrollController,
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      final item = limitedResults[index];
                      final selected = index == _highlightedIndex;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        selectedTileColor:
                            cs.primaryContainer.withValues(alpha: 0.45),
                        title: Text(
                          widget.getDisplayText(item),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        leading: widget.leadingIcon?.call(item),
                        trailing: widget.trailingIcon,
                        onTap: () => _onItemSelected(item),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: cs.outlineVariant),
                    itemCount: limitedResults.length,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
