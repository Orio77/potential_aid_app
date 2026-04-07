import 'package:flutter/material.dart';
import 'package:potential_aid_app/timeline/providers/timeline_density_provider.dart';

class DensityToggle extends StatelessWidget {
  final TimelineDensity current;
  final ValueChanged<TimelineDensity> onChanged;

  const DensityToggle({super.key, required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: TimelineDensity.values.map((d) {
        final selected = d == current;
        return GestureDetector(
          onTap: () => onChanged(d),
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              d.label,
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
