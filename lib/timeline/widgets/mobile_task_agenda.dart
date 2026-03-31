import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/breakdown/screens/task_breakdown_screen.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/projects_notifier.dart';
import 'package:potential_aid_app/timeline/providers/task_cards_notifier.dart';
import 'package:time_machine/time_machine.dart';

/// Mobile-friendly agenda list of tasks grouped by deadline date.
/// Replaces the horizontal task grid on narrow screens (< 600 px).
class MobileTaskAgenda extends ConsumerWidget {
  final int depth;

  const MobileTaskAgenda({super.key, required this.depth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksByDate = ref.watch(taskCardsNotifierProvider(depth));

    if (tasksByDate.isEmpty) {
      return const Center(child: Text('No tasks with deadlines this month'));
    }

    // Sort dates ascending.
    final sortedDates = tasksByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final tasks = tasksByDate[date]!;
        return _DateSection(date: date, tasks: tasks);
      },
    );
  }
}

// ── Date section ─────────────────────────────────────────────────────────────

class _DateSection extends StatelessWidget {
  final LocalDate date;
  final List<TaskData> tasks;

  const _DateSection({required this.date, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final today = LocalDate.today();
    final isToday = date == today;
    final isOverdue = date < today;

    final Color headerColor = isToday
        ? Colors.blue.shade700
        : isOverdue
            ? Colors.red.shade700
            : Colors.grey.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Row(
              children: [
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Divider(
                    color: headerColor.withValues(alpha: 0.35),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ),
          // Task rows
          ...tasks.map((task) => _TaskRow(task: task)),
        ],
      ),
    );
  }

  String _formatDate(LocalDate date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dayName = days[date.dayOfWeek.value - 1];
    final monthName = months[date.monthOfYear - 1];
    return '$dayName, $monthName ${date.dayOfMonth}';
  }
}

// ── Single task row ──────────────────────────────────────────────────────────

class _TaskRow extends ConsumerWidget {
  final TaskData task;

  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsync = ref.watch(projectProvider(task.projectId));

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TaskBreakdownScreen(task: task),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Completion indicator
              Icon(
                task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: task.isCompleted
                    ? Colors.green.shade600
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 10),
              // Task name
              Expanded(
                child: Text(
                  task.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted ? Colors.grey : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Project name chip
              projectAsync.when(
                data: (project) => project == null
                    ? const SizedBox.shrink()
                    : _ProjectChip(name: project.name),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectChip extends StatelessWidget {
  final String name;
  const _ProjectChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
