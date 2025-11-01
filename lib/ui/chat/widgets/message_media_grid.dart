import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/message_media_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/utils/media_layout_calculator.dart';

class MessageMediaGrid extends StatelessWidget {
  const MessageMediaGrid({
    super.key,
    required this.mediaFiles,
    this.onMediaTap,
  });

  final List<MediaFile> mediaFiles;
  final Function(int index)? onMediaTap;

  @override
  Widget build(BuildContext context) {
    if (mediaFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final layoutConfig = MediaLayoutCalculator.calculateLayout(mediaFiles.length);
    final visibleFiles = mediaFiles.take(layoutConfig.visibleItemsCount).toList();
    final hasOverlay = mediaFiles.length > layoutConfig.visibleItemsCount;
    final remainingCount = mediaFiles.length - layoutConfig.visibleItemsCount;

    return SizedBox(
      width: layoutConfig.gridWidth.w,
      child: Wrap(
        spacing: MediaLayoutCalculator.spacing.w,
        runSpacing: MediaLayoutCalculator.spacing.h,
        children: List.generate(visibleFiles.length, (index) {
          final isLastItem = index == visibleFiles.length - 1;
          final showOverlay = hasOverlay && isLastItem;

          return _buildMediaItem(
            context,
            mediaFile: visibleFiles[index],
            size: layoutConfig.itemSize,
            showOverlay: showOverlay,
            remainingCount: remainingCount,
            index: index, // Pass the index for tap handling
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
