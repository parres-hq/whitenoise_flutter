import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper class to test tooltip positioning logic
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

void main() {
  group('Tooltip Positioning Tests', () {
    const double screenWidth = 375.0;
    const double screenHeight = 812.0;
    const double tooltipWidth = 280.0;
    const double tooltipMaxHeight = 200.0;

    group('Vertical positioning (showBelow)', () {
      test('should show below when there is enough space', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(100, 100),
          targetSize: const Size(50, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        expect(position.showBelow, isTrue);
      });

      test('should show above when there is not enough space below', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(100, 700), // Near bottom of screen
          targetSize: const Size(50, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        expect(position.showBelow, isFalse);
      });

      test('should show above when target is at bottom edge', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(100, 780),
          targetSize: const Size(50, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        expect(position.showBelow, isFalse);
      });
    });

    group('Horizontal positioning (tooltipLeft)', () {
      test('should center tooltip under target when there is space', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(187.5, 100), // Center of screen
          targetSize: const Size(50, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        // Should be centered: targetCenter (212.5) - tooltipWidth/2 (140) = 72.5
        expect(position.tooltipLeft, closeTo(72.5, 0.1));
      });

      test('should clamp to left edge when target is near left edge', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(10, 100), // Near left edge
          targetSize: const Size(50, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        expect(position.tooltipLeft, equals(16.0)); // Minimum padding
      });

      test('should clamp to right edge when target is near right edge', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(350, 100), // Near right edge
          targetSize: const Size(50, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        // Should be clamped to: screenWidth (375) - tooltipWidth (280) - padding (16) = 79
        expect(position.tooltipLeft, equals(79.0));
      });
    });

    group('Arrow positioning (arrowLeft)', () {
      test('should position arrow to point to target when tooltip is centered', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(187.5, 100), // Center of screen
          targetSize: const Size(50, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        // targetCenter (212.5) - tooltipLeft (72.5) - arrowHalfWidth (6) = 134
        expect(position.arrowLeft, closeTo(134.0, 0.1));
      });

      test('should position arrow to point to target when tooltip is left-clamped', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(10, 100), // Target near left edge
          targetSize: const Size(50, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        // targetCenter (35) - tooltipLeft (16) - arrowHalfWidth (6) = 13
        expect(position.arrowLeft, equals(13.0));
      });

      test('should position arrow to point to target when tooltip is right-clamped', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(350, 100), // Target near right edge
          targetSize: const Size(50, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        // targetCenter (375) - tooltipLeft (79) - arrowHalfWidth (6) = 290
        // But clamped to max: tooltipWidth (280) - arrowHalfWidth (6) - padding (6) = 268
        expect(position.arrowLeft, equals(268.0));
      });

      test('should clamp arrow to minimum position', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(0, 100), // Target at very left edge
          targetSize: const Size(10, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        expect(position.arrowLeft, equals(12.0)); // Minimum arrow position
      });

      test('should clamp arrow to maximum position', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(370, 100), // Target at very right edge
          targetSize: const Size(10, 30),
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        expect(position.arrowLeft, equals(268.0)); // Maximum arrow position
      });
    });

    group('Edge cases', () {
      test('should handle zero-sized target', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(100, 100),
          targetSize: Size.zero,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          tooltipWidth: tooltipWidth,
          tooltipMaxHeight: tooltipMaxHeight,
        );

        expect(position.showBelow, isTrue);
        expect(position.tooltipLeft, isA<double>());
        expect(position.arrowLeft, isA<double>());
      });

      test('should handle very small screen', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(50, 50),
          targetSize: const Size(20, 20),
          screenWidth: 200.0, // Small screen
          screenHeight: 300.0,
          tooltipWidth: 150.0, // Smaller tooltip to fit
          tooltipMaxHeight: tooltipMaxHeight,
        );

        expect(position.tooltipLeft, greaterThanOrEqualTo(16.0));
        expect(position.tooltipLeft, lessThanOrEqualTo(200.0 - 150.0 - 16.0));
      });

      test('should handle tooltip wider than screen', () {
        final position = TooltipPositioning.calculatePosition(
          targetPosition: const Offset(100, 100),
          targetSize: const Size(50, 30),
          screenWidth: 200.0, // Small screen
          screenHeight: screenHeight,
          tooltipWidth: 300.0, // Tooltip wider than screen
          tooltipMaxHeight: tooltipMaxHeight,
        );

        // Should be clamped to minimum possible position
        expect(position.tooltipLeft, equals(16.0));
      });
    });
  });
}