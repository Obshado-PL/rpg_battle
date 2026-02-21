import 'package:flutter/material.dart';

class MapPathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final Set<int> clearedIndices;

  MapPathPainter({
    required this.nodePositions,
    required this.clearedIndices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < nodePositions.length - 1; i++) {
      final from = nodePositions[i];
      final to = nodePositions[i + 1];
      final isCleared = clearedIndices.contains(i);

      if (isCleared) {
        // Solid green line for cleared paths
        final paint = Paint()
          ..color = Colors.green.withValues(alpha: 0.6)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawLine(from, to, paint);
      } else {
        // Dotted grey line for locked paths
        final paint = Paint()
          ..color = Colors.grey.withValues(alpha: 0.3)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

        final path = Path();
        final dx = to.dx - from.dx;
        final dy = to.dy - from.dy;
        final distance = (Offset(dx, dy)).distance;
        final dashLength = 6.0;
        final gapLength = 4.0;
        final dashCount = distance / (dashLength + gapLength);

        for (var d = 0; d < dashCount; d++) {
          final t1 = d * (dashLength + gapLength) / distance;
          final t2 = (d * (dashLength + gapLength) + dashLength) / distance;
          if (t2 > 1) break;

          path.moveTo(
            from.dx + dx * t1,
            from.dy + dy * t1,
          );
          path.lineTo(
            from.dx + dx * t2,
            from.dy + dy * t2,
          );
        }

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPathPainter oldDelegate) {
    return oldDelegate.clearedIndices != clearedIndices;
  }
}
