import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class WnEditIconWidget extends StatelessWidget {
  const WnEditIconWidget({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 28.w,
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: context.colors.mutedForeground,
          shape: BoxShape.circle,
          border: Border.all(
            color: context.colors.secondary,
            width: 1.w,
          ),
        ),
        child: WnImage(
          AssetsPaths.icEdit,
          color: context.colors.primaryForeground,
        ),
      ),
    );
  }
}
