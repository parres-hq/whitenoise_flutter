import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';

class StartSecureChatBottomSheet extends StatelessWidget {
  final String name;
  final String email;
  final String publicKey;
  final VoidCallback? onStartChat;
  const StartSecureChatBottomSheet({
    super.key,
    required this.name,
    required this.email,
    required this.publicKey,
    this.onStartChat,
  });

  static Future<void> show({
    required BuildContext context,
    required String name,
    required String email,
    required String publicKey,
    VoidCallback? onStartChat,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Start secure chat',
      heightFactor: 0.55,
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      barrierColor: Colors.transparent,
      builder:
          (context) => StartSecureChatBottomSheet(
            name: name,
            email: email,
            publicKey: publicKey,
            onStartChat: onStartChat,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(48.h),
              CircleAvatar(
                radius: 40.r,
                backgroundImage: const AssetImage(AssetsPaths.icImage),
              ),
              Gap(12.h),
              Text(
                name,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.glitch950,
                ),
              ),
              Gap(12.h),
              Text(
                email,
                style: TextStyle(fontSize: 14.sp, color: AppColors.glitch600),
              ),
              Gap(8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  publicKey,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.glitch600),
                ),
              ),
              Gap(48.h),
            ],
          ),
        ),
        CustomFilledButton(
          onPressed: () {
            Navigator.pop(context);
            if (onStartChat != null) {
              onStartChat!();
            }
          },
          title: 'Start & Send Invite',
        ),
      ],
    );
  }
}
