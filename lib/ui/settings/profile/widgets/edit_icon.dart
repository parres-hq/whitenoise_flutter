import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class EditIconWidget extends StatelessWidget {
  const EditIconWidget({super.key, this.onTap});

  final void Function()? onTap;

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
        child: SvgPicture.asset(
          AssetsPaths.icEdit,
          colorFilter: ColorFilter.mode(
            context.colors.primaryForeground,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
