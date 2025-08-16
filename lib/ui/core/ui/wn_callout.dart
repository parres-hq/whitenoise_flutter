import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WnCallout extends StatelessWidget {
  final String title;
  final String description;

  const WnCallout({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      width: 1.sw,
      decoration: BoxDecoration(border: Border.all(color: context.colors.primary)),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                AssetsPaths.icInformation,
                colorFilter: ColorFilter.mode(
                  context.colors.primary,
                  BlendMode.srcIn,
                ),
                width: 18.w,
                height: 18.w,
              ),
              Gap(8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),
                    Gap(8.h),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
