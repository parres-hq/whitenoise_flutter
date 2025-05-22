import 'dart:io';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';

class StackedImages extends StatelessWidget {
  final List<String> imageUris;
  final double imageSize;
  final double overlap;
  final Function deleteImageCallback;

  const StackedImages({
    super.key,
    required this.imageUris,
    required this.deleteImageCallback,
    this.imageSize = 200, // Default size of each image
    this.overlap = 30, // How much each image overlaps the one before it
  });

  @override
  Widget build(BuildContext context) {
    if (imageUris.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: imageSize, // Adjust height based on images
      width: imageSize + overlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(imageUris.length + 1, (index) {
          if (index < imageUris.length) {
            final uri = imageUris[index];
            final double rotation =
                Random().nextDouble() * 10 -
                5; // Random rotation between -5° and 5°
            final double offsetX = index * (overlap); // Overlapping effect
            return Positioned(
              top: 0,
              left: offsetX,
              right: 0,
              child: Transform.rotate(
                angle: rotation * (pi / 180), // Convert degrees to radians
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      uri.startsWith("http")
                          ? CachedNetworkImage(
                            imageUrl: uri,
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageSize,
                          )
                          : Image.file(
                            File(uri),
                            fit: BoxFit.cover,
                            width: imageSize,
                            height: imageSize,
                          ),
                ),
              ),
            );
          } else {
            return Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  deleteImageCallback();
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white, // optional background color
                  ),
                  child: Icon(Icons.delete, color: Colors.red, size: 15),
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}
