import 'package:flutter/material.dart';

class CustomChatBubbleNoBorderPainter extends CustomPainter {
  final Color color;
  final Alignment alignment;
  final bool tail;

  CustomChatBubbleNoBorderPainter({
    required this.color,
    required this.alignment,
    required this.tail,
  });

  double _x = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    if (alignment == Alignment.topRight) {
      if (tail) {
        // Main rectangle (right side - no border radius)
        canvas.drawRect(
          Rect.fromLTRB(0, 0, size.width - _x, size.height),
          paint,
        );

        // Tail triangle (right side)
        var path = Path();
        path.moveTo(size.width - _x, 0);
        path.lineTo(size.width - _x, 10);
        path.lineTo(size.width, 0);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Rectangle without tail (right side - no border radius)
        canvas.drawRect(
          Rect.fromLTRB(0, 0, size.width - _x, size.height),
          paint,
        );
      }
    } else {
      if (tail) {
        // Main rectangle (left side - no border radius)
        canvas.drawRect(
          Rect.fromLTRB(_x, 0, size.width, size.height),
          paint,
        );

        // Tail triangle (left side)
        var path = Path();
        path.moveTo(_x, 0);
        path.lineTo(_x, 10);
        path.lineTo(0, 0);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Rectangle without tail (left side - no border radius)
        canvas.drawRect(
          Rect.fromLTRB(_x, 0, size.width, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
