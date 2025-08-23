import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WnIconButton extends StatelessWidget {
  final void Function()? onTap;
  final String iconPath;
  final double? padding;
  final double? size;
  final Color? buttonColor;
  final Color? iconColor;

  const WnIconButton({
    required this.onTap,
    required this.iconPath,
    this.padding,
    this.size,
    this.buttonColor,
    this.iconColor,
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
          border: Border.all(color: buttonColor ?? context.colors.input),
          color: buttonColor ?? Colors.transparent,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding ?? 12.w),
          child: SvgPicture.asset(
            iconPath,
            width: 16.w,
            height: 16.w,
            colorFilter: ColorFilter.mode(iconColor ?? context.colors.primary, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
