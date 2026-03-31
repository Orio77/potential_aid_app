import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:potential_aid_app/providers/database_provider.dart';
import 'package:potential_aid_app/schedule/widgets/complete_block_dialog.dart';
import 'package:potential_aid_app/widget/widget_update_service.dart';
import 'package:time_machine/time_machine.dart';

/// Separate Flutter entry point for [WidgetCompletionActivity].
/// Renders nothing visible — just pops a [CompleteBlockDialog] over a
/// transparent scaffold, then updates the widget and closes itself.
@pragma('vm:entry-point')
Future<void> widgetCompletionMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimeMachine.initialize({'rootBundle': rootBundle});

  final blockId =
      (await HomeWidget.getWidgetData<int>('pending_blockId')) ?? -1;
  final blockLength =
      (await HomeWidget.getWidgetData<int>('pending_blockLength')) ?? 60;

  if (blockId == -1) {
    SystemNavigator.pop();
    return;
  }

  runApp(
    ProviderScope(
      child: _WidgetCompletionApp(blockId: blockId, blockLength: blockLength),
    ),
  );
}

class _WidgetCompletionApp extends StatelessWidget {
  final int blockId;
  final int blockLength;

  const _WidgetCompletionApp({
    required this.blockId,
    required this.blockLength,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _WidgetCompletionScreen(
        blockId: blockId,
        blockLength: blockLength,
      ),
    );
  }
}

class _WidgetCompletionScreen extends ConsumerStatefulWidget {
  final int blockId;
  final int blockLength;

  const _WidgetCompletionScreen({
    required this.blockId,
    required this.blockLength,
  });

  @override
  ConsumerState<_WidgetCompletionScreen> createState() =>
      _WidgetCompletionScreenState();
}

class _WidgetCompletionScreenState
    extends ConsumerState<_WidgetCompletionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDialog());
  }

  Future<void> _showDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => CompleteBlockDialog(
        blockId: widget.blockId,
        blockLength: widget.blockLength,
      ),
    );

    final db = ref.read(databaseProvider);
    await WidgetUpdateService.updateToday(db);

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: Colors.transparent);
  }
}
