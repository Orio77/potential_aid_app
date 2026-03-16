import 'package:potential_aid_app/providers/schedule_notifier.dart';
import 'package:potential_aid_app/providers/settings_notifier.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddBlockService {
  static Future<TimeOfDay> calculateNextAvailableTime(WidgetRef ref) async {
    final settings = ref.read(settingsNotifierProvider);
    final schedule = ref.read(scheduleNotifierProvider);

    if (schedule.isEmpty) {
      final defaultMinutes = settings.defaultStartTime;
      return TimeOfDay(hour: defaultMinutes ~/ 60, minute: defaultMinutes % 60);
    }

    final lastBlockId = schedule.last;
    final lastBlock = await ref
        .read(scheduleNotifierProvider.notifier)
        .getBlockById(lastBlockId);
    final lastEndMinutes =
        lastBlock!.startMinuteOfDay + lastBlock.lengthMinutes;
    final nextStartMinutes = lastEndMinutes + settings.defaultBreakTime;

    return TimeOfDay(
      hour: nextStartMinutes ~/ 60,
      minute: nextStartMinutes % 60,
    );
  }

  static String? validateProjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project name cannot be empty';
    }

    return null;
  }
}
