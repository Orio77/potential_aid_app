import 'package:flutter/material.dart';

class ArrowPainter extends CustomPainter {
  final GlobalKey mainTaskKey;
  final List<GlobalKey> subtaskKeys;
  final BuildContext stackContext;

  ArrowPainter({
    required this.mainTaskKey,
    required this.subtaskKeys,
    required this.stackContext,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.deepPurpleAccent.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = Colors.deepPurpleAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Get main task position
    final mainTaskRenderBox =
        mainTaskKey.currentContext?.findRenderObject() as RenderBox?;
    if (mainTaskRenderBox == null) return;

    // Get the Stack's render box for coordinate conversion
    final stackRenderBox = stackContext.findRenderObject() as RenderBox?;
    if (stackRenderBox == null) return;

    // Convert main task position to Stack's coordinate system
    final mainTaskGlobalPosition = mainTaskRenderBox.localToGlobal(Offset.zero);
    final mainTaskLocalPosition = stackRenderBox.globalToLocal(
      mainTaskGlobalPosition,
    );
    final mainTaskSize = mainTaskRenderBox.size;

    // Start point: right edge, center of main task
    final startPoint = Offset(
      mainTaskLocalPosition.dx + mainTaskSize.width,
      mainTaskLocalPosition.dy + mainTaskSize.height / 2,
    );

    // Draw arrows to each subtask
    for (final subtaskKey in subtaskKeys) {
      // Check if the element is still mounted and active
      final context = subtaskKey.currentContext;
      if (context == null || !context.mounted) continue;

      final subtaskRenderBox = context.findRenderObject() as RenderBox?;
      if (subtaskRenderBox == null || !subtaskRenderBox.hasSize) continue;

      // Convert subtask position to Stack's coordinate system
      final subtaskGlobalPosition = subtaskRenderBox.localToGlobal(Offset.zero);
      final subtaskLocalPosition = stackRenderBox.globalToLocal(
        subtaskGlobalPosition,
      );
      final subtaskSize = subtaskRenderBox.size;

      // End point: left edge, center of subtask
      final endPoint = Offset(
        subtaskLocalPosition.dx,
        subtaskLocalPosition.dy + subtaskSize.height / 2,
      );

      // Only draw if there's a meaningful distance
      if ((endPoint.dx - startPoint.dx).abs() < 10) continue;

      // Draw curved line
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);

      // Create smoother curve control points
      final horizontalDistance = endPoint.dx - startPoint.dx;

      final controlPoint1 = Offset(
        startPoint.dx + horizontalDistance * 0.6,
        startPoint.dy,
      );
      final controlPoint2 = Offset(
        startPoint.dx + horizontalDistance * 0.4,
        endPoint.dy,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        endPoint.dx,
        endPoint.dy,
      );

      canvas.drawPath(path, paint);

      _drawArrowhead(canvas, arrowPaint, endPoint);
    }
  }

  void _drawArrowhead(Canvas canvas, Paint paint, Offset tip) {
    const arrowSize = 10.0;
    final path = Path();

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(tip.dx - arrowSize, tip.dy - arrowSize / 2);
    path.lineTo(tip.dx - arrowSize, tip.dy + arrowSize / 2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
