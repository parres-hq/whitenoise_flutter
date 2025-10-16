import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/chat/states/media_file_upload.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.mediaItem,
    required this.isActive,
    required this.onTap,
  });

  final MediaFileUpload mediaItem;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: mediaItem.isUploading ? null : onTap,
      child: mediaItem.when(
        uploading:
            (filePath) => _buildThumbnail(
              context,
              filePath: filePath,
              overlay: _buildUploadingOverlay(),
            ),
        uploaded:
            (file) => _buildThumbnail(
              context,
              filePath: file.filePath,
              overlay: isActive ? _buildDeleteOverlay(context) : null,
            ),
        failed:
            (filePath, error) => _buildThumbnail(
              context,
              filePath: filePath,
              overlay: _buildErrorOverlay(context),
            ),
      ),
    );
  }

  Widget _buildThumbnail(
    BuildContext context, {
    required String filePath,
    Widget? overlay,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: context.colors.mutedForeground,
              width: 1.w,
            ),
          ),
          child: ClipRRect(
            child: Image.file(
              File(filePath),
              height: 32.h,
              width: 32.w,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        ),
        if (overlay != null) overlay,
      ],
    );
  }

  Widget _buildDeleteOverlay(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
          ),
          child: Center(
            child: SizedBox(
              width: 18.w,
              height: 18.h,
              child: WnImage(
                AssetsPaths.icTrashCan,
                color: context.colors.solidNeutralWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return Positioned.fill(
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 14.w,
          ),
        ),
      ),
    );
  }
}
