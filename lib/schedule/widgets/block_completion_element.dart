import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/schedule/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/schedule/providers/schedule_notifier.dart';
import 'package:potential_aid_app/schedule/services/completion_service.dart';

class BlockCompletionElement extends ConsumerStatefulWidget {
  final BlockData block;
  final Function(int blockId, int minutesCompleted)? onBlockCompletion;

  const BlockCompletionElement({
    super.key,
    required this.block,
    required this.onBlockCompletion,
  });

  @override
  ConsumerState<BlockCompletionElement> createState() =>
      BlockCompletionElementState();
}

class BlockCompletionElementState
    extends ConsumerState<BlockCompletionElement> {
  final _completionController = TextEditingController();
  late int blockLength;
  late int completionCount;

  @override
  void initState() {
    super.initState();
    blockLength = widget.block.lengthMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 22, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Block time',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints.tightFor(
                    width: CompletionService.fieldWidth(blockLength),
                  ),
                  child: TextField(
                    controller: _completionController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Minutes',
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
                        blockLength.toString().length + 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'up to $blockLength min',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Use full block length ($blockLength min)',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      completionCount = blockLength;
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
    final minutesCompleted = int.tryParse(inputText);

    if (minutesCompleted == null) {
      return null;
    }

    try {
      final res = await ref
          .read(scheduleNotifierProvider.notifier)
          .addBlockCompletion(widget.block.id, minutesCompleted);

      widget.onBlockCompletion?.call(widget.block.id, minutesCompleted);
      final date = ref.read(dateNotifierProvider).toDateTimeUnspecified();
      ref.invalidate(scheduleDayCompletionPercentagesProvider(date));

      return res;
    } catch (e) {
      rethrow;
    }
  }
}
