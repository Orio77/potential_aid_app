import 'package:flutter/material.dart';

// AppBar-based search widget for use in Scaffold.appBar
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String normalTitle;
  final String searchHint;
  final Function(String) onSearchChanged;
  final TextStyle? titleStyle;
  final Widget? leading;
  final List<Widget>? additionalActions;
  final Color? backgroundColor;

  const SearchAppBar({
    super.key,
    required this.normalTitle,
    required this.onSearchChanged,
    this.searchHint = 'Search...',
    this.titleStyle,
    this.leading,
    this.additionalActions,
    this.backgroundColor,
  });

  @override
  State<SearchAppBar> createState() => SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SearchAppBarState extends State<SearchAppBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void activateSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        widget.onSearchChanged('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                border: InputBorder.none,
                hintStyle: const TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 18),
              onChanged: widget.onSearchChanged,
            )
          : Text(
              widget.normalTitle,
              style: widget.titleStyle ??
                  const TextStyle(fontWeight: FontWeight.w400, fontSize: 35),
            ),
      centerTitle: true,
      leading: widget.leading,
      actions: [
        IconButton(
          onPressed: _toggleSearch,
          icon: Icon(_isSearching ? Icons.close : Icons.search),
        ),
        ...?widget.additionalActions,
      ],
      backgroundColor: widget.backgroundColor ??
          Theme.of(context).colorScheme.inversePrimary,
    );
  }
}

// Regular widget-based search bar for use in layouts
class SearchBar extends StatefulWidget {
  final String normalTitle;
  final String searchHint;
  final Function(String) onSearchChanged;
  final TextStyle? titleStyle;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const SearchBar({
    super.key,
    required this.normalTitle,
    required this.onSearchChanged,
    this.searchHint = 'Search...',
    this.titleStyle,
    this.height = 56.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        widget.onSearchChanged('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: widget.onSearchChanged,
                  )
                : Text(
                    widget.normalTitle,
                    style: widget.titleStyle ??
                        TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                  ),
          ),
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.grey.shade600,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
