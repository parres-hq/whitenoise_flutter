import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/widgets/media_image.dart';
import 'package:whitenoise/ui/chat/widgets/media_thumbnail.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class MediaModal extends StatefulWidget {
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
  State<MediaModal> createState() => _MediaModalState();
}

class _MediaModalState extends State<MediaModal> {
  static const double _thumbnailSize = 32.0;
  static const double _thumbnailSpacing = 12.0;

  late PageController _pageController;
  late ScrollController _thumbnailScrollController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _thumbnailScrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveThumbnail();
    });
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
    });
    _scrollToActiveThumbnail(animate: true);
  }

  void _scrollToActiveThumbnail({bool animate = false}) {
    if (!_thumbnailScrollController.hasClients) return;

    final scrollPosition = _currentIndex * (_thumbnailSize.w + _thumbnailSpacing.w);

    if (animate) {
      _thumbnailScrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
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

  @override
  Widget build(BuildContext context) {
    return WnDialog.custom(
      backgroundColor: context.colors.surface,
      customChild: _buildModalContent(),
    );
  }

  Widget _buildModalContent() {
    return SizedBox(
      height: 480.h,
      width: 345.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Gap(12.h),
          Expanded(
            child: Stack(
              children: [
                _buildImageViewer(),
                if (widget.mediaFiles.length > 1)
                  Positioned(
                    bottom: 12.h,
                    left: 12.w,
                    right: 12.w,
                    child: _buildThumbnailStrip(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        WnAvatar(
          imageUrl: widget.senderImagePath ?? '',
          size: 36.w,
          displayName: widget.senderName,
        ),
        Gap(8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.senderName,
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
                DateFormat('dd/MM/yyyy - HH:mm').format(widget.timestamp.toLocal()),
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
    );
  }

  Widget _buildImageViewer() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.mediaFiles.length,
      physics: const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: MediaImage(
            mediaFile: widget.mediaFiles[index],
            width: double.infinity,
            height: double.infinity,
          ),
        );
      },
    );
  }

  Widget _buildThumbnailStrip() {
    return SizedBox(
      height: _thumbnailSize.h,
      child: ListView.separated(
        controller: _thumbnailScrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: widget.mediaFiles.length,
        physics: const ClampingScrollPhysics(),
        separatorBuilder: (context, index) => SizedBox(width: _thumbnailSpacing.w),
        itemBuilder: (context, index) {
          return MediaThumbnail(
            mediaFile: widget.mediaFiles[index],
            isActive: _currentIndex == index,
            onTap: () => _onThumbnailTap(index),
          );
        },
      ),
    );
  }
}
