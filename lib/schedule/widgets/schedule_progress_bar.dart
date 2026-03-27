import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/schedule/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/stats/widgets/progress_bar.dart';
import 'package:time_machine/time_machine.dart';

class ScheduleProgressBar extends ConsumerWidget {
  const ScheduleProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(dateNotifierProvider);
    final dateTime = date.toDateTimeUnspecified();
    final today = LocalDate.today().toDateTimeUnspecified();
    final completionValue = ref.watch(
      scheduleDayCompletionPercentagesProvider(dateTime),
    );
    return completionValue.when(
      data: (data) {
        return (dateTime.isBefore(today) || dateTime.isAtSameMomentAs(today))
            ? ProgressBar(completionValue: data)
            : SizedBox.shrink();
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text("Error: $error"),
    );
  }
}
