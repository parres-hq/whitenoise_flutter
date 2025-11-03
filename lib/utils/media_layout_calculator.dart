class MediaLayoutConfig {
  const MediaLayoutConfig({
    required this.visibleItemsCount,
    required this.gridWidth,
    required this.itemSize,
  });

  final int visibleItemsCount;
  final double gridWidth;
  final double itemSize;
}

class MediaLayoutCalculator {
  static const double singleImageSize = 250.0;
  static const double twoImagesSize = 140.0;
  static const double multipleImagesSize = 92.0;
  static const double spacing = 4.0;

  static MediaLayoutConfig calculateLayout(int mediaCount) {
    if (mediaCount == 1) {
      return const MediaLayoutConfig(
        visibleItemsCount: 1,
        gridWidth: singleImageSize,
        itemSize: singleImageSize,
      );
    }

    if (mediaCount == 2) {
      return _buildConfig(
        columns: 2,
        visibleItemsCount: 2,
        itemSize: twoImagesSize,
      );
    }

    final visibleItemsCount = mediaCount <= 5 ? 3 : 6;

    return _buildConfig(
      columns: 3,
      visibleItemsCount: visibleItemsCount,
      itemSize: multipleImagesSize,
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
    );
  }
}
