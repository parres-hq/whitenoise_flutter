import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:whitenoise/config/providers/media_file_downloads_provider.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/media_image.dart';
import 'package:whitenoise/ui/chat/widgets/media_thumbnail.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class MediaModal extends ConsumerStatefulWidget {
  const MediaModal({
    super.key,
    required this.mediaFiles,
    required this.initialIndex,
    required this.senderName,
    required this.senderImagePath,
    required this.timestamp,
  });

  final List<MediaFile> mediaFiles;
  final int initialIndex;
  final String senderName;
  final String? senderImagePath;
  final DateTime timestamp;

  @override
  ConsumerState<MediaModal> createState() => _MediaModalState();
}

class _MediaModalState extends ConsumerState<MediaModal> {
  static const double _thumbnailSize = 36.0;
  static const double _thumbnailSpacing = 8.0;

  late PageController _pageController;
  late ScrollController _thumbnailScrollController;
  late int _currentIndex;
  bool _isImageZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbnailScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _downloadMediaFiles();
      _scrollToActiveThumbnail();
    });
  }

  void _downloadMediaFiles() {
    ref.read(mediaFileDownloadsProvider.notifier).downloadMediaFiles(widget.mediaFiles);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailScrollController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _isImageZoomed = false;
    });
    _scrollToActiveThumbnail(animate: true);
  }

  void _onZoomChanged(bool isZoomed) {
    if (_isImageZoomed == isZoomed) return;
    setState(() {
      _isImageZoomed = isZoomed;
    });
  }

  void _scrollToActiveThumbnail({bool animate = false}) {
    if (!_thumbnailScrollController.hasClients) return;

    final scrollPosition = _currentIndex * (_thumbnailSize.w + _thumbnailSpacing.w);

    if (animate) {
      _thumbnailScrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _thumbnailScrollController.jumpTo(scrollPosition);
    }
  }

  void _onThumbnailTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  ScrollPhysics get _scrollPhysics {
    return _isImageZoomed ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 15.0),
      child: Dialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0.r)),
        insetPadding: EdgeInsets.symmetric(horizontal: 0.w),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child:
                    _isImageZoomed
                        ? const SizedBox.shrink()
                        : _MediaModalHeader(
                          senderName: widget.senderName,
                          senderImagePath: widget.senderImagePath,
                          timestamp: widget.timestamp,
                        ),
              ),
              Expanded(
                child: _MediaModalImageView(
                  mediaFiles: widget.mediaFiles,
                  pageController: _pageController,
                  onPageChanged: _onPageChanged,
                  onZoomChanged: _onZoomChanged,
                  scrollPhysics: _scrollPhysics,
                ),
              ),
              if (widget.mediaFiles.length > 1)
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child:
                      _isImageZoomed
                          ? const SizedBox.shrink()
                          : _MediaModalThumbnailStrip(
                            mediaFiles: widget.mediaFiles,
                            currentIndex: _currentIndex,
                            thumbnailSize: _thumbnailSize,
                            thumbnailSpacing: _thumbnailSpacing,
                            scrollController: _thumbnailScrollController,
                            onThumbnailTap: _onThumbnailTap,
                          ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaModalHeader extends StatelessWidget {
  const _MediaModalHeader({
    required this.senderName,
    required this.senderImagePath,
    required this.timestamp,
  });

  final String senderName;
  final String? senderImagePath;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h, top: 48.h),
      child: Row(
        children: [
          WnAvatar(
            imageUrl: senderImagePath ?? '',
            size: 36.w,
            displayName: senderName,
          ),
          Gap(8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(2.h),
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(timestamp.toLocal()),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: context.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: WnImage(
              AssetsPaths.icClose,
              size: 24.w,
              color: context.colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaModalImageView extends StatelessWidget {
  const _MediaModalImageView({
    required this.mediaFiles,
    required this.pageController,
    required this.onPageChanged,
    required this.onZoomChanged,
    required this.scrollPhysics,
  });

  final List<MediaFile> mediaFiles;
  final PageController pageController;
  final void Function(int) onPageChanged;
  final void Function(bool) onZoomChanged;
  final ScrollPhysics scrollPhysics;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: mediaFiles.length,
      physics: scrollPhysics,
      itemBuilder: (context, index) {
        return MediaImage(
          mediaFile: mediaFiles[index],
          width: double.infinity,
          height: double.infinity,
          onZoomChanged: onZoomChanged,
        );
      },
    );
  }
}

class _MediaModalThumbnailStrip extends StatelessWidget {
  const _MediaModalThumbnailStrip({
    required this.mediaFiles,
    required this.currentIndex,
    required this.thumbnailSize,
    required this.thumbnailSpacing,
    required this.scrollController,
    required this.onThumbnailTap,
  });

  final List<MediaFile> mediaFiles;
  final int currentIndex;
  final double thumbnailSize;
  final double thumbnailSpacing;
  final ScrollController scrollController;
  final void Function(int) onThumbnailTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 48.h),
      child: SizedBox(
        height: thumbnailSize.h,
        child: ListView.separated(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: mediaFiles.length,
          physics: const ClampingScrollPhysics(),
          separatorBuilder: (context, index) => SizedBox(width: thumbnailSpacing.w),
          itemBuilder: (context, index) {
            return MediaThumbnail(
              mediaFile: mediaFiles[index],
              isActive: currentIndex == index,
              onTap: () => onThumbnailTap(index),
              size: thumbnailSize.w,
            );
          },
        ),
      ),
    );
  }
}
