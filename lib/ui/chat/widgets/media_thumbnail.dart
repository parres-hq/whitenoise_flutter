import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/models/media_file_upload.dart';
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
              overlay: _uploadingOverlay(context),
            ),
        uploaded:
            (file, originalFilePath) => _buildThumbnail(
              context,
              filePath: originalFilePath,
              overlay: isActive ? _uploadedOverlay(context) : null,
            ),
        failed:
            (filePath, error) => _buildThumbnail(
              context,
              filePath: filePath,
              overlay: _failedOverlay(context),
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

  Widget _uploadedOverlay(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Container(
          width: 32.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: context.colors.solidNeutralBlack.withValues(alpha: 0.5),
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

  Widget _uploadingOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: BoxDecoration(
          color: context.colors.solidNeutralBlack.withValues(alpha: 0.5),
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.colors.solidNeutralWhite,
            ),
          ),
        ),
      ),
    );
  }

  Widget _failedOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: BoxDecoration(
          color: context.colors.solidNeutralBlack.withValues(alpha: 0.5),
        ),
        child: Center(
          child: WnImage(
            AssetsPaths.icErrorFilled,
            color: context.colors.destructive,
            size: 14.w,
          ),
        ),
      ),
    );
  }
}
