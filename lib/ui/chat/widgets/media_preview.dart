import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/models/media_file_upload.dart';
import 'package:whitenoise/ui/chat/widgets/media_preview_thumbnail.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class MediaPreview extends StatefulWidget {
  const MediaPreview({
    super.key,
    required this.mediaItems,
    required this.onRemoveImage,
    required this.onAddMore,
    this.isReply = false,
  });

  final List<MediaFileUpload> mediaItems;
  final void Function(int index) onRemoveImage;
  final VoidCallback onAddMore;
  final bool isReply;
  @override
  State<MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<MediaPreview> {
  static const double _imageWidth = 285.0;
  static const double _imageHeight = 250.0;
  static const double _imageSpacing = 8.0;
  static const double _thumbnailSpacing = 12.0;

  final _pageController = PageController();
  int _currentMediaIndex = 0;
  bool _isDeleteEnabled = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mediaItems.isEmpty) {
      setState(() {
        _currentMediaIndex = 0;
        _isDeleteEnabled = false;
      });
    } else if (_currentMediaIndex >= widget.mediaItems.length && widget.mediaItems.isNotEmpty) {
      setState(() {
        _currentMediaIndex = widget.mediaItems.length - 1;
        _isDeleteEnabled = false;
      });
      _pageController.jumpToPage(_currentMediaIndex);
    }
  }

  void _handleThumbnailTap(int index) {
    if (_currentMediaIndex == index && _isDeleteEnabled) {
      widget.onRemoveImage(index);
      setState(() {
        _isDeleteEnabled = false;
      });
    } else if (_currentMediaIndex == index) {
      setState(() {
        _isDeleteEnabled = true;
      });
    } else {
      setState(() {
        _isDeleteEnabled = false;
      });
      _scrollToImage(index);
    }
  }

  void _scrollToImage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: widget.isReply ? 4.h : 14.h),
      child: SizedBox(
        height: _imageHeight.h,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentMediaIndex = index;
                  _isDeleteEnabled = false;
                });
              },
              itemBuilder: (context, index) {
                final mediaItem = widget.mediaItems[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: _imageSpacing.w),
                  child: mediaItem.when(
                    uploading:
                        (filePath) => Stack(
                          children: [
                            ClipRRect(
                              child: Image.file(
                                File(filePath),
                                height: _imageHeight.h,
                                width: _imageWidth.w,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                color: context.colors.solidNeutralBlack.withValues(alpha: 0.5),
                                child: Center(
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.colors.solidNeutralWhite,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    uploaded:
                        (file, originalFilePath) => ClipRRect(
                          child: Image.file(
                            File(originalFilePath),
                            height: _imageHeight.h,
                            width: _imageWidth.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                    failed:
                        (filePath, error) => Stack(
                          children: [
                            ClipRRect(
                              child: Image.file(
                                File(filePath),
                                height: _imageHeight.h,
                                width: _imageWidth.w,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                color: context.colors.solidNeutralBlack.withValues(alpha: 0.5),
                                child: Center(
                                  child: WnImage(
                                    AssetsPaths.icErrorFilled,
                                    color: context.colors.destructive,
                                    size: 48.w,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                  itemCount: widget.mediaItems.length + 1,
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
                    final itemIndex = index - 1;
                    final mediaItem = widget.mediaItems[itemIndex];

                    return MediaPreviewThumbnail(
                      mediaItem: mediaItem,
                      isActive: _currentMediaIndex == itemIndex,
                      isMarkedForDeletion: _isDeleteEnabled && _currentMediaIndex == itemIndex,
                      onTap: () => _handleThumbnailTap(itemIndex),
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
