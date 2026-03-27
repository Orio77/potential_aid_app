import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:potential_aid_app/projects/screens/project_category_list_screen.dart';
import 'package:potential_aid_app/stats/screens/completion_stats_screen.dart';
import 'package:potential_aid_app/timeline/screens/timeline_screen.dart';
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
    if (!mounted) return false;
    if (event is! KeyDownEvent) return false;

    final ctrl = HardwareKeyboard.instance.isControlPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;
    final key = event.logicalKey;

    // Escape / Alt+Left — go back
    if (key == LogicalKeyboardKey.escape ||
        (alt && !ctrl && key == LogicalKeyboardKey.arrowLeft)) {
      Navigator.maybePop(context);
      return true;
    }

    // Ctrl+Shift+P — global search
    if (ctrl && shift && key == LogicalKeyboardKey.keyP) {
      _showSearch();
      return true;
    }

    // Navigation shortcuts
    if (ctrl && !shift) {
      if (key == LogicalKeyboardKey.digit1) {
        _goToSchedule();
        return true;
      }
      if (key == LogicalKeyboardKey.digit2) {
        _navigateTo(const CompletionStatsScreen());
        return true;
      }
      if (key == LogicalKeyboardKey.digit3) {
        _navigateTo(const TimelineScreen());
        return true;
      }
      if (key == LogicalKeyboardKey.digit4) {
        _navigateTo(const ProjectCategoryListScreen());
        return true;
      }
      if (key == LogicalKeyboardKey.digit5) {
        _navigateTo(
          const ProjectCategoryListScreen(initialShowCategories: false),
        );
        return true;
      }
    }

    return false;
  }

  void _goToSchedule() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _navigateTo(Widget screen) {
    Navigator.popUntil(context, (route) => route.isFirst);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showSearch() {
    if (_isSearchOpen) return;
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
