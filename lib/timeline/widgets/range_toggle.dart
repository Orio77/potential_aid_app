import 'package:flutter/material.dart';
import 'package:potential_aid_app/timeline/providers/timeline_range_provider.dart';

class RangeToggle extends StatelessWidget {
  final TimelineRange current;
  final ValueChanged<TimelineRange> onChanged;

  const RangeToggle({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TimelineRange.values.map((r) {
        final selected = r == current;
        return GestureDetector(
          onTap: () => onChanged(r),
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              r.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
