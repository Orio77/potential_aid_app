import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';

class DeleteBlockDialog extends ConsumerStatefulWidget {
  final int blockId;

  const DeleteBlockDialog({super.key, required this.blockId});

  @override
  ConsumerState<DeleteBlockDialog> createState() => _DeleteTaskDialogState();
}

class _DeleteTaskDialogState extends ConsumerState<DeleteBlockDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(child: Text('Delete this block?')),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onTertiary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('NO'),
              ),
            ),
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  ref
                      .read(scheduleNotifierProvider.notifier)
                      .removeBlock(widget.blockId);
                  Navigator.of(context).pop();
                },
                child: const Text('YES'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
