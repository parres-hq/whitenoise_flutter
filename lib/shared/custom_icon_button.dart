import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class CustomIconButton extends StatelessWidget {
  final void Function()? onTap;
  final String iconPath;

  const CustomIconButton({
    required this.onTap,
    required this.iconPath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.baseMuted),
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: SvgPicture.asset(iconPath, width: 16.w, height: 16.w),
        ),
      ),
    );
  }
}
