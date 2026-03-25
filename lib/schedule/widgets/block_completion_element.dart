import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/data/database.dart';
import 'package:potential_aid_app/providers/completion_notifier.dart';
import 'package:potential_aid_app/providers/date_notifier.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 8),
        const Icon(Icons.timer),
        const SizedBox(width: 16),
        ConstrainedBox(
          constraints: BoxConstraints.tightFor(
            width: CompletionService.fieldWidth(blockLength),
          ),
          child: TextField(
            controller: _completionController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.always,
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
        const SizedBox(width: 12),
        Text(' / $blockLength minutes'),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () {
            completionCount = blockLength;
            setState(() {
              _completionController.text = completionCount.toString();
            });
          },
          child: Text('>>'),
        ),
      ],
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
