import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class CustomIconButton extends StatelessWidget {
  final void Function()? onTap;
  final String iconPath;
  final double? padding;
  final double? size;

  const CustomIconButton({
    required this.onTap,
    required this.iconPath,
    this.padding,
    this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size ?? 40.h,
        width: size,
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.input),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding ?? 12.w),
          child: WnImage(
            iconPath,
            width: 16.w,
            height: 16.w,
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }
}
