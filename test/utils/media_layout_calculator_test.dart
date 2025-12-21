import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/utils/media_layout_calculator.dart';

void main() {
  group('MediaLayoutCalculator', () {
    const double testMaxWidth = 300.0;

    group('with 1 media file', () {
      test('returns 1 visible item', () {
        final result = MediaLayoutCalculator.calculateLayout(1, testMaxWidth);
        expect(result.visibleItemsCount, 1);
      });

      test('returns grid width equal to max width', () {
        final result = MediaLayoutCalculator.calculateLayout(1, testMaxWidth);
        expect(result.gridWidth, testMaxWidth);
      });

      test('returns item size equal to max width', () {
        final result = MediaLayoutCalculator.calculateLayout(1, testMaxWidth);
        expect(result.itemSize, testMaxWidth);
      });
    });

    group('with 2 media files', () {
      test('returns 2 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(2, testMaxWidth);
        expect(result.visibleItemsCount, 2);
      });

      test('returns grid width respecting max width', () {
        final result = MediaLayoutCalculator.calculateLayout(2, testMaxWidth);
        expect(result.gridWidth, lessThanOrEqualTo(testMaxWidth));
        final expectedWidth = testMaxWidth;
        expect(result.gridWidth, closeTo(expectedWidth, 0.1));
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(2, testMaxWidth);
        final expectedItemSize = (testMaxWidth - MediaLayoutCalculator.spacing) / 2;
        expect(result.itemSize, closeTo(expectedItemSize, 0.1));
      });
    });

    group('with 3 media files', () {
      test('returns 3 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(3, testMaxWidth);
        expect(result.visibleItemsCount, 3);
      });

      test('returns grid width respecting max width', () {
        final result = MediaLayoutCalculator.calculateLayout(3, testMaxWidth);
        expect(result.gridWidth, lessThanOrEqualTo(testMaxWidth));
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(3, testMaxWidth);
        final expectedItemSize =
            (testMaxWidth - (MediaLayoutCalculator.spacing * 2)) / 3;
        expect(result.itemSize, closeTo(expectedItemSize, 0.1));
      });
    });

    group('with 4 media files', () {
      test('returns 3 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(4, testMaxWidth);
        expect(result.visibleItemsCount, 3);
      });

      test('returns grid width respecting max width', () {
        final result = MediaLayoutCalculator.calculateLayout(4, testMaxWidth);
        expect(result.gridWidth, lessThanOrEqualTo(testMaxWidth));
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(4, testMaxWidth);
        final expectedItemSize =
            (testMaxWidth - (MediaLayoutCalculator.spacing * 2)) / 3;
        expect(result.itemSize, closeTo(expectedItemSize, 0.1));
      });
    });

    group('with 5 media files', () {
      test('returns 3 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(5, testMaxWidth);
        expect(result.visibleItemsCount, 3);
      });

      test('returns grid width respecting max width', () {
        final result = MediaLayoutCalculator.calculateLayout(5, testMaxWidth);
        expect(result.gridWidth, lessThanOrEqualTo(testMaxWidth));
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(5, testMaxWidth);
        final expectedItemSize =
            (testMaxWidth - (MediaLayoutCalculator.spacing * 2)) / 3;
        expect(result.itemSize, closeTo(expectedItemSize, 0.1));
      });
    });

    group('with 6 media files', () {
      test('returns 6 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(6, testMaxWidth);
        expect(result.visibleItemsCount, 6);
      });

      test('returns grid width respecting max width', () {
        final result = MediaLayoutCalculator.calculateLayout(6, testMaxWidth);
        expect(result.gridWidth, lessThanOrEqualTo(testMaxWidth));
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(6, testMaxWidth);
        final expectedItemSize =
            (testMaxWidth - (MediaLayoutCalculator.spacing * 2)) / 3;
        expect(result.itemSize, closeTo(expectedItemSize, 0.1));
      });
    });

    group('with 7 media files', () {
      test('returns 6 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(7, testMaxWidth);
        expect(result.visibleItemsCount, 6);
      });

      test('returns grid width respecting max width', () {
        final result = MediaLayoutCalculator.calculateLayout(7, testMaxWidth);
        expect(result.gridWidth, lessThanOrEqualTo(testMaxWidth));
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(7, testMaxWidth);
        final expectedItemSize =
            (testMaxWidth - (MediaLayoutCalculator.spacing * 2)) / 3;
        expect(result.itemSize, closeTo(expectedItemSize, 0.1));
      });
    });

    group('with 8 media files', () {
      test('returns 6 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(8, testMaxWidth);
        expect(result.visibleItemsCount, 6);
      });

      test('returns grid width respecting max width', () {
        final result = MediaLayoutCalculator.calculateLayout(8, testMaxWidth);
        expect(result.gridWidth, lessThanOrEqualTo(testMaxWidth));
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(8, testMaxWidth);
        final expectedItemSize =
            (testMaxWidth - (MediaLayoutCalculator.spacing * 2)) / 3;
        expect(result.itemSize, closeTo(expectedItemSize, 0.1));
      });
    });

    group('with 9 media files', () {
      test('returns 6 visible items', () {
        final result = MediaLayoutCalculator.calculateLayout(9, testMaxWidth);
        expect(result.visibleItemsCount, 6);
      });

      test('returns grid width respecting max width', () {
        final result = MediaLayoutCalculator.calculateLayout(9, testMaxWidth);
        expect(result.gridWidth, lessThanOrEqualTo(testMaxWidth));
      });

      test('returns expected item size', () {
        final result = MediaLayoutCalculator.calculateLayout(9, testMaxWidth);
        final expectedItemSize =
            (testMaxWidth - (MediaLayoutCalculator.spacing * 2)) / 3;
        expect(result.itemSize, closeTo(expectedItemSize, 0.1));
      });
    });
  });
}
