import 'package:flutter/material.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';

class ScheduleProgressBar extends StatelessWidget {
  const ScheduleProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final completionValue = 0.9;
    final color = CompletionUtils.getCompletionColor(completionValue * 100);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completionValue, // 7 out of 20 tasks
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Percentage text
          Align(
            alignment: Alignment.center,
            child: Text(
              '80%',
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
}
