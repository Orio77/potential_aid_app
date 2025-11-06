import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DurationPickerDialog extends StatefulWidget {
  final int initialDuration;

  const DurationPickerDialog({super.key, required this.initialDuration});

  @override
  State<DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<DurationPickerDialog> {
  late int _duration;
  final durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
    durationController.text = _duration.toString();
    durationController.addListener(() {
      final text = durationController.text.trim();
      final value = int.tryParse(text);
      if (value != null) {
        setState(() {
          _duration = value;
        });
      }
    });
  }

  @override
  void dispose() {
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_duration minutes'),
          ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: 30),
            child: TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _duration = 30);
                  durationController.text = '30';
                },
                child: const Text('30m'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _duration = 60);
                  durationController.text = '60';
                },
                child: const Text('1h'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => {
            _duration = int.parse(durationController.text.trim()),
            Navigator.of(context).pop(_duration),
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
