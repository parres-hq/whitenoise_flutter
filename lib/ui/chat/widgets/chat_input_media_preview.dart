import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/chat/widgets/media_thumbnail.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';

class ChatInputMediaPreview extends StatefulWidget {
  const ChatInputMediaPreview({
    super.key,
    required this.imagePaths,
    required this.onRemoveImage,
    required this.onAddMore,
    this.isReply = false,
  });

  final List<String> imagePaths;
  final void Function(int index) onRemoveImage;
  final VoidCallback onAddMore;
  final bool isReply;
  @override
  State<ChatInputMediaPreview> createState() => _ChatInputMediaPreviewState();
}

class _ChatInputMediaPreviewState extends State<ChatInputMediaPreview> {
  static const double _imageWidth = 285.0;
  static const double _imageHeight = 250.0;
  static const double _imageSpacing = 8.0;
  static const double _thumbnailSpacing = 12.0;

  final _scrollController = ScrollController();
  int? _activeThumbIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleThumbnailTap(int index) {
    if (_activeThumbIndex == index) {
      widget.onRemoveImage(index);
      setState(() {
        _activeThumbIndex = null;
      });
    } else {
      setState(() {
        _activeThumbIndex = index;
      });
      _scrollToImage(index);
    }
  }

  void _scrollToImage(int index) {
    final scrollPosition = index * (_imageWidth.w + _imageSpacing.w);
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imagePaths.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: widget.isReply ? 8.h : 16.h),
      child: SizedBox(
        height: _imageHeight.h,
        child: Stack(
          children: [
            ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: widget.imagePaths.length,
              separatorBuilder: (context, index) => SizedBox(width: _imageSpacing.w),
              itemBuilder: (context, index) {
                final imagePath = widget.imagePaths[index];
                return ClipRRect(
                  child: Image.file(
                    File(imagePath),
                    height: _imageHeight.h,
                    width: _imageWidth.w,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 12.h,
              left: 12.w,
              right: 0,
              child: SizedBox(
                height: 32.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.imagePaths.length + 1,
                  separatorBuilder: (context, index) => SizedBox(width: _thumbnailSpacing.w),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return WnIconButton(
                        onTap: widget.onAddMore,
                        iconPath: AssetsPaths.icAdd,
                        size: 32.w,
                        padding: 8.w,
                        buttonColor: context.colors.secondary,
                        borderColor: context.colors.secondary,
                        iconColor: context.colors.primary,
                      );
                    }
                    final imageIndex = index - 1;
                    final imagePath = widget.imagePaths[imageIndex];
                    return MediaThumbnail(
                      path: imagePath,
                      isActive: _activeThumbIndex == imageIndex,
                      onTap: () => _handleThumbnailTap(imageIndex),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
