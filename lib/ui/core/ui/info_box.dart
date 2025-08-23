import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';

class InfoBox extends StatelessWidget {
  const InfoBox({
    super.key,
    required this.colorTheme,
    required this.title,
    required this.description,
  });

  final Color colorTheme;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: colorTheme.withValues(alpha: 0.1)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.w),
            child: SvgPicture.asset(
              AssetsPaths.icWarning,
              width: 16.w,
              height: 16.w,
              colorFilter: ColorFilter.mode(colorTheme, BlendMode.srcIn),
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: colorTheme,
                  ),
                ),
                Gap(8.h),
                Text(
                  description,
                  style: TextStyle(fontSize: 14.sp, color: colorTheme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
