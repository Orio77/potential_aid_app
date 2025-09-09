import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';
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
            ? _buildProgressBar(context, calculateCompletionPercentage(data))
            : SizedBox.shrink();
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => Text("Error: $error"),
    );
  }

  Widget _buildProgressBar(BuildContext context, double completionValue) {
    final color = CompletionUtils.getCompletionColor(completionValue * 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completionValue,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.center,
            child: Text(
              '${(completionValue * 100).toStringAsFixed(2)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
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
