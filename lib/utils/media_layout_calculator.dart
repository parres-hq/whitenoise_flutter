class MediaLayoutConfig {
  const MediaLayoutConfig({
    required this.visibleItemsCount,
    required this.gridWidth,
    required this.itemSize,
    required this.columns,
  });

  final int visibleItemsCount;
  final double gridWidth;
  final double itemSize;
  final int columns;
}

class MediaLayoutCalculator {
  static const double spacing = 4.0;

  static MediaLayoutConfig calculateLayout(int mediaCount, double maxWidth) {
    if (mediaCount == 1) {
      final itemSize = maxWidth;
      return MediaLayoutConfig(
        visibleItemsCount: 1,
        gridWidth: itemSize,
        itemSize: itemSize,
        columns: 1,
      );
    }

    if (mediaCount == 2) {
      final availableWidth = maxWidth - spacing;
      final itemSize = availableWidth / 2;
      return _buildConfig(
        columns: 2,
        visibleItemsCount: 2,
        itemSize: itemSize,
      );
    }

    final visibleItemsCount = mediaCount <= 5 ? 3 : 6;
    final columns = 3;
    final availableWidth = maxWidth - (spacing * (columns - 1));
    final itemSize = availableWidth / columns;

    return _buildConfig(
      columns: columns,
      visibleItemsCount: visibleItemsCount,
      itemSize: itemSize,
    );
  }

  static MediaLayoutConfig _buildConfig({
    required int columns,
    required int visibleItemsCount,
    required double itemSize,
  }) {
    final gridWidth = (itemSize * columns) + (spacing * (columns - 1));
    return MediaLayoutConfig(
      visibleItemsCount: visibleItemsCount,
      gridWidth: gridWidth,
      itemSize: itemSize,
      columns: columns,
    );
  }
}
