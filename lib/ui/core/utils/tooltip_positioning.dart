import 'package:flutter/material.dart';

class TooltipPositioning {
  static TooltipPosition calculatePosition({
    required Offset targetPosition,
    required Size targetSize,
    required double screenWidth,
    required double screenHeight,
    required double tooltipWidth,
    required double tooltipMaxHeight,
  }) {
    // Check if there's enough space below the target
    final spaceBelow = screenHeight - (targetPosition.dy + targetSize.height);
    final showBelow = spaceBelow >= tooltipMaxHeight;

    // Calculate tooltip position with screen constraints
    final maxRight = screenWidth - tooltipWidth - 16.0;
    final tooltipLeft = (targetPosition.dx + targetSize.width / 2 - tooltipWidth / 2)
        .clamp(16.0, maxRight > 16.0 ? maxRight : 16.0);

    // Calculate arrow position relative to tooltip
    final targetCenter = targetPosition.dx + targetSize.width / 2;
    final arrowLeft = (targetCenter - tooltipLeft - 6.0).clamp(12.0, tooltipWidth - 12.0);

    return TooltipPosition(
      showBelow: showBelow,
      tooltipLeft: tooltipLeft,
      arrowLeft: arrowLeft,
    );
  }
}

class TooltipPosition {
  final bool showBelow;
  final double tooltipLeft;
  final double arrowLeft;

  TooltipPosition({
    required this.showBelow,
    required this.tooltipLeft,
    required this.arrowLeft,
  });
}