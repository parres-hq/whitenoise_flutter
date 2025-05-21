import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.textController,
    this.padding,
    this.contentPadding,
    this.autofocus = true,
    this.hintText,
    this.obscureText = false,
  });

  final TextEditingController textController;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final bool autofocus;
  final String? hintText;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 24.w),
      child: TextField(
        controller: textController,
        autofocus: autofocus,
        obscureText: obscureText,
        obscuringCharacter: '•',
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.color727772, fontSize: 14.sp),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.colorE2E2E2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.colorE2E2E2),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.colorE2E2E2),
          ),
          contentPadding:
              contentPadding ??
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
      ),
    );
  }
}
