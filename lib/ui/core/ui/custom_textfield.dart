import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../themes/src/extensions.dart';

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
                color: context.colors.secondaryForeground,
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
                  color: context.colors.mutedForeground,
                  fontSize: 14.sp,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: context.colors.baseMuted),
                  borderRadius: BorderRadius.zero,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.colors.baseMuted),
                  borderRadius: BorderRadius.zero,
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: context.colors.baseMuted),
                  borderRadius: BorderRadius.zero,
                ),
                contentPadding:
                    contentPadding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
