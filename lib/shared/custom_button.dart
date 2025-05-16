import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.title,
    this.buttonType = ButtonType.primary,
  });

  final void Function()? onPressed;
  final String title;
  final ButtonType buttonType;

  @override
  Widget build(BuildContext context) {
    final isPrimary = buttonType == ButtonType.primary;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isPrimary ? AppColors.color202320 : AppColors.colorF2F2F2,
          foregroundColor: isPrimary ? AppColors.colorF9F9F9 : AppColors.color2D312D,
          disabledBackgroundColor: isPrimary ? AppColors.color202320.withValues(alpha: 0.5) : AppColors.colorF2F2F2,
          disabledForegroundColor: isPrimary ? AppColors.colorF9F9F9 : AppColors.color2D312D,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0.r),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

enum ButtonType { primary, secondary }
