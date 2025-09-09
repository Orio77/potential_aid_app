import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/widgets/stats/progress_bar.dart';
import 'package:time_machine/time_machine.dart';

class ScheduleProgressBar extends ConsumerWidget {
  const ScheduleProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(dateNotifierProvider).toDateTimeUnspecified();
    final today = LocalDate.today().toDateTimeUnspecified();
    final blocksWithCompletionsAsync = ref.watch(
      scheduleDayCompletionPercentagesProvider(date),
    );

    return blocksWithCompletionsAsync.when(
      data: (data) {
        return (date.isBefore(today) || date.isAtSameMomentAs(today))
            ? ProgressBar(completionValue: calculateCompletionPercentage(data))
            : SizedBox.shrink();
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text("Error: $error"),
    );
  }

  double calculateCompletionPercentage(
    Map<BlockData, BlockCompletionData> completions,
  ) {
    double sum = 0.0;

    if (completions.isEmpty) {
      return sum;
    }

    for (var entry in completions.entries) {
      final block = entry.key;
      final completion = entry.value;

      final blockCompletion = (completion.count / block.lengthMinutes).clamp(
        0.0,
        1.0,
      );
      sum += blockCompletion;
    }

    return (sum / completions.length).clamp(0.0, 1.0);
  }
}
