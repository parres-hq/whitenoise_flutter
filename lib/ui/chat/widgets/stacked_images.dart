import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/themes/colors.dart';

class StackedImages extends StatelessWidget {
  final List<String> imageUris;
  final VoidCallback onDelete;
  final double imageSize;
  final double overlapPercentage;
  final int maxImagesToShow;

  const StackedImages({
    super.key,
    required this.imageUris,
    required this.onDelete,
    this.imageSize = 60,
    this.overlapPercentage = 0.15, // 15% overlap
    this.maxImagesToShow = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUris.isEmpty) return const SizedBox.shrink();

    // Calculate responsive sizes
    final double responsiveImageSize = imageSize.w;
    final double overlap = responsiveImageSize * overlapPercentage;
    final int imagesToShow = min(imageUris.length, maxImagesToShow);
    final double totalWidth = responsiveImageSize + (overlap * (imagesToShow - 1));

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          SizedBox(
            height: responsiveImageSize,
            width: totalWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Display the stacked images
                ...List.generate(imagesToShow, (index) {
                  final uri = imageUris[index];
                  final double rotation = Random().nextDouble() * 10 - 5;
                  final double offsetX = index * overlap;

                  return Positioned(
                    left: offsetX,
                    child: Transform.rotate(
                      angle: rotation * (pi / 180),
                      child: _buildImage(uri, responsiveImageSize),
                    ),
                  );
                }),

                // Delete button positioned on top of the last image
                if (imageUris.isNotEmpty)
                  Positioned(
                    top: 6.h,
                    right: 2.w,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 20.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withValues(alpha: 0.9),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.glitch600,
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.close,
                          size: 12.sp,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String uri, double size) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.glitch80, width: 4),
      ),
      child:
          uri.startsWith('http')
              ? CachedNetworkImage(
                imageUrl: uri,
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[200],
                      width: size,
                      height: size,
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[300],
                      width: size,
                      height: size,
                      child: Icon(Icons.error, size: 24.sp),
                    ),
              )
              : Image.file(
                File(uri),
                fit: BoxFit.cover,
                width: size,
                height: size,
              ),
    );
  }
}
