import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.path,
    required this.isActive,
    required this.onTap,
  });

  final String path;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
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
                File(path),
                height: 32.h,
                width: 32.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ),
          if (isActive)
            Positioned.fill(
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
            ),
        ],
      ),
    );
  }
}
