import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/message_media_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/utils/media_layout_calculator.dart';

class MessageMediaGrid extends ConsumerWidget {
  const MessageMediaGrid({
    super.key,
    required this.mediaFiles,
    this.onMediaTap,
  });

  final List<MediaFile> mediaFiles;
  final Function(int index)? onMediaTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mediaFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    Future.microtask(() {
      ref.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(mediaFiles);
    });

    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth * 0.74;
    final bubblePadding = 16.w;
    final maxMediaWidth = maxBubbleWidth - bubblePadding;

    final layoutConfig = MediaLayoutCalculator.calculateLayout(
      mediaFiles.length,
      maxMediaWidth,
    );
    final visibleFiles = mediaFiles.take(layoutConfig.visibleItemsCount).toList();
    final hasOverlay = mediaFiles.length > layoutConfig.visibleItemsCount;
    final remainingCount = mediaFiles.length - layoutConfig.visibleItemsCount;

    final rows = (visibleFiles.length / layoutConfig.columns).ceil();

    return SizedBox(
      width: layoutConfig.gridWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (rowIndex) {
          final startIndex = rowIndex * layoutConfig.columns;
          final endIndex = (startIndex + layoutConfig.columns).clamp(0, visibleFiles.length);
          final rowItems = visibleFiles.sublist(startIndex, endIndex);

          return Padding(
            padding: EdgeInsets.only(
              bottom: rowIndex < rows - 1 ? MediaLayoutCalculator.spacing : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int colIndex = 0; colIndex < rowItems.length; colIndex++) ...[
                  if (colIndex > 0) const SizedBox(width: MediaLayoutCalculator.spacing),
                  SizedBox(
                    width: layoutConfig.itemSize,
                    height: layoutConfig.itemSize,
                    child: _buildMediaItem(
                      context,
                      mediaFile: rowItems[colIndex],
                      size: layoutConfig.itemSize,
                      showOverlay: hasOverlay && (startIndex + colIndex == visibleFiles.length - 1),
                      remainingCount: remainingCount,
                      index: startIndex + colIndex,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMediaItem(
    BuildContext context, {
    required MediaFile mediaFile,
    required double size,
    required bool showOverlay,
    required int remainingCount,
    required int index,
  }) {
    final tile = MessageMediaTile(
      mediaFile: mediaFile,
      size: size,
    );

    Widget content = tile;

    if (showOverlay) {
      content = Stack(
        children: [
          tile,
          Positioned.fill(
            child: Container(
              color: context.colors.solidNeutralBlack.withValues(alpha: 0.5),
              child: Center(
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.solidPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onMediaTap != null) {
      return GestureDetector(
        onTap: () => onMediaTap!(index),
        child: content,
      );
    }

    return content;
  }
}
