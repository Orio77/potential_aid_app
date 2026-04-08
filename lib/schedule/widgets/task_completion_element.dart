import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/schedule/providers/schedule_notifier.dart';
import 'package:potential_aid_app/schedule/services/completion_service.dart';

class TaskCompletionElement extends ConsumerStatefulWidget {
  final TaskData task;
  final Function(int taskId, int completionCount)? onTaskCompletion;

  const TaskCompletionElement({
    super.key,
    required this.task,
    required this.onTaskCompletion,
  });

  @override
  ConsumerState<TaskCompletionElement> createState() =>
      TaskCompletionElementState();
}

class TaskCompletionElementState extends ConsumerState<TaskCompletionElement> {
  final _completionController = TextEditingController();
  bool saveAllSubtasks = true;
  late int taskLength;
  late int completionCount;

  @override
  void initState() {
    super.initState();
    _completionController.text = widget.task.current.toString();
    taskLength = widget.task.endGoal;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rawUnit = widget.task.unit ?? '';
    final unitLabel = rawUnit.trim().isEmpty ? 'units' : rawUnit.trim();

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.task_alt, size: 22, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.task.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(
                    width: CompletionService.fieldWidth(taskLength),
                  ),
                  child: TextField(
                    controller: _completionController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Total',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        taskLength.toString().length + 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'of $taskLength $unitLabel',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Set total to goal ($taskLength)',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      completionCount = taskLength;
                      setState(() {
                        _completionController.text = completionCount.toString();
                      });
                    },
                    icon: const Icon(Icons.flag_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> saveCompletion() async {
    final inputText = _completionController.text.trim();
    final completionCount = int.tryParse(inputText);

    if (completionCount == null) {
      return null;
    }

    final delta = CompletionService.calculateTaskDelta(
      completionCount,
      widget.task.current,
    );

    if (delta == null) {
      return null;
    }

    try {
      final res = await ref
          .read(scheduleNotifierProvider.notifier)
          .addTaskCompletion(widget.task.id, delta);

      widget.onTaskCompletion?.call(widget.task.id, completionCount);

      return res;
    } catch (e) {
      rethrow;
    }
  }
}
