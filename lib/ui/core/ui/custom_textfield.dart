import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.textController,
    this.padding,
    this.contentPadding,
    this.autofocus = true,
    this.hintText,
    this.obscureText = false,
    this.label,
    this.readOnly = false,
  });

  final TextEditingController? textController;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final bool autofocus;
  final String? hintText;
  final bool obscureText;
  final String? label;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label,
              style: TextStyle(
                color: AppColors.glitch900,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Gap(8.h),
          ],
          SizedBox(
            height: 40.h,
            child: TextField(
              controller: textController,
              autofocus: autofocus,
              obscureText: obscureText,
              readOnly: readOnly,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.glitch600,
                  fontSize: 14.sp,
                ),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.glitch200),
                  borderRadius: BorderRadius.zero,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.glitch200),
                  borderRadius: BorderRadius.zero,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.glitch200),
                  borderRadius: BorderRadius.zero,
                ),
                contentPadding:
                    contentPadding ??
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
