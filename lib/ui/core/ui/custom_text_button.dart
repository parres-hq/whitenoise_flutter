import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/src/extensions.dart';

class CustomTextButton extends StatelessWidget {
  const CustomTextButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.addPadding = false,
    this.horizontalPadding = 24.0,
    this.bottomPadding = 24.0,
  });

  final void Function()? onPressed;
  final String title;
  final bool addPadding;
  final double horizontalPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: context.colors.secondaryForeground,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: context.colors.secondaryForeground,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(
          title,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),
      ),
    );

    if (addPadding) {
      return Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding.w,
          right: horizontalPadding.w,
          bottom: bottomPadding.h,
        ),
        child: button,
      );
    }
    return button;
  }
}
