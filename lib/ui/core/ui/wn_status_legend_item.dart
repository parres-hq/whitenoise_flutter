import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WnStatusLegendItem extends StatelessWidget {
  const WnStatusLegendItem({
    super.key,
    required this.color,
    required this.label,
    this.textColor,
    this.fontSize,
    this.fontWeight,
  });

  final Color color;
  final String label;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        Gap(8.w),
        Text(
          label,
          style: TextStyle(
            color: textColor ?? context.colors.primaryForeground,
            fontSize: fontSize ?? 14.sp,
            fontWeight: fontWeight ?? FontWeight.w600,
          ),
        ),
      ],
    );
  }
}