import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:potential_aid_app/widgets/common/global_search_dialog.dart';

class GlobalSearchLauncher extends StatefulWidget {
  final Widget child;

  const GlobalSearchLauncher({super.key, required this.child});

  @override
  State<GlobalSearchLauncher> createState() => _GlobalSearchLauncherState();
}

class _GlobalSearchLauncherState extends State<GlobalSearchLauncher> {
  bool _isSearchOpen = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed &&
        HardwareKeyboard.instance.isShiftPressed &&
        event.logicalKey == LogicalKeyboardKey.keyP) {
      _showSearch();
      return true;
    }
    return false;
  }

  void _showSearch() {
    if (!mounted || _isSearchOpen) return;
    _isSearchOpen = true;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
          ),
          child: const GlobalSearchDialog(),
        ),
      ),
    ).then((_) => _isSearchOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final topAreaHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topAreaHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 300) {
                _showSearch();
              }
            },
          ),
        ),
      ],
    );
  }
}
