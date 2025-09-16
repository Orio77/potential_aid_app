import 'package:flutter/material.dart';
import 'package:potential_aid_app/utils/completion_utils.dart';

class ProgressBar extends StatelessWidget {
  final double completionValue;
  const ProgressBar({super.key, required this.completionValue});

  @override
  Widget build(BuildContext context) {
    final color = CompletionUtils.getCompletionColor(completionValue * 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isVeryCompact =
            constraints.maxHeight < 50 || constraints.maxWidth < 200;
        bool isCompact =
            constraints.maxWidth < 300 || constraints.maxHeight < 80;
        bool isExtremelyTight = constraints.maxHeight < 25;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExtremelyTight
                ? 2
                : (isVeryCompact ? 4 : (isCompact ? 8 : 20)),
            vertical: isExtremelyTight
                ? 0
                : (isVeryCompact ? 2 : (isCompact ? 4 : 12)),
          ),
          child: isExtremelyTight
              ? Container(
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: completionValue,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isVeryCompact) SizedBox(height: isCompact ? 4 : 8),
                    Flexible(
                      child: Container(
                        height: isVeryCompact ? 4 : (isCompact ? 6 : 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completionValue,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                    ),
                    if (!isVeryCompact) ...[
                      SizedBox(height: isCompact ? 2 : 4),
                      Flexible(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            '${(completionValue * 100).toStringAsFixed(2)}%',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isCompact ? 12 : 15,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
