import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/media_layout_calculator.dart';

void main() {
  group('MediaLayoutCalculator', () {
    group('with 1 media file', () {
      test('returns 1 visible item', () {
        final result = MediaLayoutCalculator.calculateLayout(1);
        expect(result.visibleItemsCount, 1);
      });

      test('returns expected grid width', () {
        final result = MediaLayoutCalculator.calculateLayout(1);
        expect(result.gridWidth, 250.0);
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(1);
        expect(result.itemSize, 250.0);
      });
    });

    group('with 2 media files', () {
      test('returns 2 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(2);
        expect(result.visibleItemsCount, 2);
      });

      test('returns expected grid width', () {
        final result = MediaLayoutCalculator.calculateLayout(2);
        // (140 * 2) + (4 * 1) = 284
        expect(result.gridWidth, 284.0);
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(2);
        expect(result.itemSize, 140.0);
      });
    });

    group('with 3 media files', () {
      test('returns 3 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(3);
        expect(result.visibleItemsCount, 3);
      });

      test('returns expected grid width', () {
        final result = MediaLayoutCalculator.calculateLayout(3);
        // (92 * 3) + (4 * 2) = 284
        expect(result.gridWidth, 284.0);
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(3);
        expect(result.itemSize, 92.0);
      });
    });

    group('with 4 media files', () {
      test('returns 3 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(4);
        expect(result.visibleItemsCount, 3);
      });

      test('returns expected grid width', () {
        final result = MediaLayoutCalculator.calculateLayout(4);
        // (92 * 3) + (4 * 2) = 284
        expect(result.gridWidth, 284.0);
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(4);
        expect(result.itemSize, 92.0);
      });
    });

    group('with 5 media files', () {
      test('returns 3 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(5);
        expect(result.visibleItemsCount, 3);
      });

      test('returns expected grid width', () {
        final result = MediaLayoutCalculator.calculateLayout(5);
        // (92 * 3) + (4 * 2) = 284
        expect(result.gridWidth, 284.0);
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(5);
        expect(result.itemSize, 92.0);
      });
    });

    group('with 6 media files', () {
      test('returns 6 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(6);
        expect(result.visibleItemsCount, 6);
      });

      test('returns expected grid width', () {
        final result = MediaLayoutCalculator.calculateLayout(6);
        // (92 * 3) + (4 * 2) = 284
        expect(result.gridWidth, 284.0);
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(6);
        expect(result.itemSize, 92.0);
      });
    });

    group('with 7 media files', () {
      test('returns 6 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(7);
        expect(result.visibleItemsCount, 6);
      });

      test('returns expected grid width', () {
        final result = MediaLayoutCalculator.calculateLayout(7);
        // (92 * 3) + (4 * 2) = 284
        expect(result.gridWidth, 284.0);
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(7);
        expect(result.itemSize, 92.0);
      });
    });

    group('with 8 media files', () {
      test('returns 6 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(8);
        expect(result.visibleItemsCount, 6);
      });

      test('returns expected grid width', () {
        final result = MediaLayoutCalculator.calculateLayout(8);
        // (92 * 3) + (4 * 2) = 284
        expect(result.gridWidth, 284.0);
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(8);
        expect(result.itemSize, 92.0);
      });
    });

    group('with 9 media files', () {
      test('returns 6 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(9);
        expect(result.visibleItemsCount, 6);
      });

      test('returns expected grid width', () {
        final result = MediaLayoutCalculator.calculateLayout(9);
        // (92 * 3) + (4 * 2) = 284
        expect(result.gridWidth, 284.0);
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(9);
        expect(result.itemSize, 92.0);
      });
    });
  });
}
