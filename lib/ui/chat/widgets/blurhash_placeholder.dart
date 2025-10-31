import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class BlurhashPlaceholder extends StatelessWidget {
  const BlurhashPlaceholder({
    super.key,
    required this.hash,
    this.width,
    this.height,
  });

  final String? hash;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (hash == null || hash!.isEmpty) {
      return _buildFallback(context);
    }

    return BlurHash(
      hash: hash!,
      imageFit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: context.colors.baseMuted,
      child: Center(
        child: WnImage(
          AssetsPaths.icImage,
          size: 48.w,
          color: context.colors.mutedForeground,
        ),
      ),
    );
  }
}
