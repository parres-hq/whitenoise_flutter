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

  final double _x = 10.0;
  final double _borderRadius = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (alignment == Alignment.topRight) {
      if (tail) {
        // Main rounded rectangle (right side)
        final mainRect = RRect.fromLTRBAndCorners(
          0, 0, size.width - _x, size.height,
          topLeft: Radius.circular(_borderRadius),
          topRight: Radius.circular(2.0), // Less rounded where tail connects
          bottomLeft: Radius.circular(_borderRadius),
          bottomRight: Radius.circular(_borderRadius),
        );
        canvas.drawRRect(mainRect, paint);

        // Tail triangle (right side)
        final path = Path();
        path.moveTo(size.width - _x, 0);
        path.lineTo(size.width - _x, 10);
        path.lineTo(size.width, 0);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Rounded rectangle without tail (right side)
        final rect = RRect.fromLTRBAndCorners(
          0, 0, size.width - _x, size.height,
          topLeft: Radius.circular(_borderRadius),
          topRight: Radius.circular(_borderRadius),
          bottomLeft: Radius.circular(_borderRadius),
          bottomRight: Radius.circular(_borderRadius),
        );
        canvas.drawRRect(rect, paint);
      }
    } else {
      if (tail) {
        // Main rounded rectangle (left side)
        final mainRect = RRect.fromLTRBAndCorners(
          _x, 0, size.width, size.height,
          topLeft: Radius.circular(2.0), // Less rounded where tail connects
          topRight: Radius.circular(_borderRadius),
          bottomLeft: Radius.circular(_borderRadius),
          bottomRight: Radius.circular(_borderRadius),
        );
        canvas.drawRRect(mainRect, paint);

        // Tail triangle (left side)
        final path = Path();
        path.moveTo(_x, 0);
        path.lineTo(_x, 10);
        path.lineTo(0, 0);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Rounded rectangle without tail (left side)
        final rect = RRect.fromLTRBAndCorners(
          _x, 0, size.width, size.height,
          topLeft: Radius.circular(_borderRadius),
          topRight: Radius.circular(_borderRadius),
          bottomLeft: Radius.circular(_borderRadius),
          bottomRight: Radius.circular(_borderRadius),
        );
        canvas.drawRRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
