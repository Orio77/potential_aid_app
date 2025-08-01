import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/providers/schedule_notifier.dart';

class CompleteTaskDialog extends ConsumerStatefulWidget {
  final int blockId;
  final int blockLength;

  const CompleteTaskDialog({
    super.key,
    required this.blockId,
    required this.blockLength,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CompleteTaskDialogState();
}

class _CompleteTaskDialogState extends ConsumerState<CompleteTaskDialog> {
  final TextEditingController _controller = TextEditingController();
  late int minutesCompleted;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(
        child: Text('Complete This Task', textAlign: TextAlign.center),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Minutes Completed'),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints.tightFor(
                  width: _fieldWidth(widget.blockLength),
                ),
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      widget.blockLength.toString().length,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(' / ${widget.blockLength}'),
            ],
          ),
        ],
      ),

      actionsPadding: const EdgeInsets.only(bottom: 20, right: 12, left: 12),
      actionsAlignment: MainAxisAlignment.center,
      actionsOverflowAlignment: OverflowBarAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final inputText = _controller.text.trim();
            if (inputText.isEmpty) {
              _showErrorMessage(
                'Please enter the number of minutes completed.',
              );
              return;
            }

            final parsedMinutes = int.tryParse(inputText);
            if (parsedMinutes == null || !_isValidInput(parsedMinutes)) {
              return;
            }

            minutesCompleted = parsedMinutes;
            _saveCompletion(widget.blockId, minutesCompleted);
            Navigator.of(context).pop();
          },
          child: const Text('Complete'),
        ),
      ],
    );
  }

  double _fieldWidth(int max) {
    const double base = 36;
    const double perDigit = 12;
    final int digits = max.toString().length.clamp(2, 3);
    return base + perDigit * digits;
  }

  bool _isValidInput(int input) {
    return input > 0 && input <= widget.blockLength;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.black)),
        backgroundColor: Theme.of(context).colorScheme.onError,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _saveCompletion(int blockId, int minutesCompleted) async {
    await ref
        .read(scheduleNotifierProvider.notifier)
        .addTaskCompletion(blockId, minutesCompleted);
  }
}
