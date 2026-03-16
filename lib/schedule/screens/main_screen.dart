import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/schedule/widgets/add_block_dialog_button.dart';
import 'package:potential_aid_app/schedule/widgets/schedule_app_bar.dart';
import 'package:potential_aid_app/schedule/widgets/schedule_body.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const ScheduleAppBar(),
      body: ScheduleBody(),
      floatingActionButton: AddBlockDialogButton(),
    );
  }
}
