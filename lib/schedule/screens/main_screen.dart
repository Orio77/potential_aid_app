import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/schedule/widgets/add_block_dialog.dart';
import 'package:potential_aid_app/schedule/widgets/add_block_dialog_button.dart';
import 'package:potential_aid_app/schedule/widgets/log_work_dialog.dart';
import 'package:potential_aid_app/schedule/widgets/schedule_app_bar.dart';
import 'package:potential_aid_app/schedule/widgets/schedule_body.dart';
import 'package:time_machine/time_machine.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
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
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    if (event is! KeyDownEvent) return false;
    if (!HardwareKeyboard.instance.isControlPressed) return false;

    if (event.logicalKey == LogicalKeyboardKey.keyN) {
      final isPast =
          ref.read(dateNotifierProvider).compareTo(LocalDate.today()) < 0;
      if (isPast) {
        showLogWorkDialog(context);
      } else {
        showAddBlockDialog(context);
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = ref.watch(dateNotifierProvider);
    final isPast = currentDate.compareTo(LocalDate.today()) < 0;

    return Scaffold(
      appBar: const ScheduleAppBar(),
      body: ScheduleBody(),
      floatingActionButton: isPast
          ? FloatingActionButton.extended(
              onPressed: () => showLogWorkDialog(context),
              icon: const Icon(Icons.add_task),
              label: const Text('Log Work'),
            )
          : AddBlockDialogButton(),
    );
  }
}
