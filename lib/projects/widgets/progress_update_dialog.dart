import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/project_tasks_notifier.dart';
import 'package:potential_aid_app/projects/providers/task_progress_providers.dart';

class ProgressUpdateDialog extends ConsumerStatefulWidget {
  final TaskData task;

  const ProgressUpdateDialog({super.key, required this.task});

  @override
  ConsumerState<ProgressUpdateDialog> createState() =>
      _ProgressUpdateDialogState();
}

class _ProgressUpdateDialogState extends ConsumerState<ProgressUpdateDialog> {
  late TextEditingController _controller;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.current.toString());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final value = int.tryParse(_controller.text);
    return value != null && value >= widget.task.current && !_isLoading;
  }

  Future<void> _submit() async {
    final value = int.tryParse(_controller.text);
    if (value == null || value < widget.task.current) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(projectTasksNotifier(widget.task.projectId).notifier)
          .updateTask(
            widget.task.id,
            TaskCompanion(current: Value(value)),
          );

      if (widget.task.parentTaskId != null) {
        ref.invalidate(taskSubtasksProvider(widget.task.parentTaskId!));
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final unit = task.unit ?? '';
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(task.name, overflow: TextOverflow.ellipsis),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${task.current} / ${task.endGoal}${unit.isNotEmpty ? ' $unit' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New value',
                suffixText: unit.isNotEmpty ? unit : null,
                border: const OutlineInputBorder(),
                helperText: 'Must be ≥ ${task.current}',
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) {
                if (_canSubmit) _submit();
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

Future<void> showProgressUpdateDialog(BuildContext context, TaskData task) {
  return showDialog(
    context: context,
    builder: (_) => ProgressUpdateDialog(task: task),
  );
}
