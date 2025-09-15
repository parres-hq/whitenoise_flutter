import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class WnIconButton extends StatelessWidget {
  final void Function()? onTap;
  final String iconPath;
  final double? padding;
  final double? size;
  final Color? buttonColor;
  final Color? iconColor;
  final Color? borderColor;

  const WnIconButton({
    required this.onTap,
    required this.iconPath,
    this.padding,
    this.size,
    this.buttonColor,
    this.iconColor,
    this.borderColor,
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
          border: Border.all(color: borderColor ?? buttonColor ?? context.colors.input),
          color: buttonColor ?? Colors.transparent,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding ?? 12.w),
          child: WnImage(
            iconPath,
            size: 16.w,
            color: iconColor ?? context.colors.primary,
          ),
        ),
      ),
    );
  }
}
