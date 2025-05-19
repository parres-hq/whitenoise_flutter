import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/shared/custom_bottom_sheet.dart';
import 'package:whitenoise/shared/custom_button.dart';

class ChatInvitationSheet extends StatelessWidget {
  final String name;
  final String email;
  final String publicKey;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  
  const ChatInvitationSheet({
    super.key,
    required this.name,
    required this.email,
    required this.publicKey,
    this.onAccept,
    this.onDecline,
  });

  static Future<void> show({
    required BuildContext context,
    required String name,
    required String email,
    required String publicKey,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Invitation to join secure chat',
      heightFactor: 0.55,
      backgroundColor: Colors.white,
      builder: (context) => ChatInvitationSheet(
        name: name,
        email: email,
        publicKey: publicKey,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Gap(24.h),
              CircleAvatar(radius: 40.r, backgroundImage: AssetImage(AssetsPaths.icImage)),
              Gap(12.h),
              Text(name, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w500, color: AppColors.color202320)),
              Gap(12.h),
              Text(email, style: TextStyle(fontSize: 14.sp, color: AppColors.color727772)),
              Gap(8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  publicKey,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: AppColors.color727772),
                ),
              ),
              Gap(48.h),
            ],
          ),
        ),
        const Spacer(),
        CustomButton(
          buttonType: ButtonType.secondary,
          onPressed: () {
            Navigator.pop(context);
            if (onDecline != null) {
              onDecline!();
            }
          },
          title: 'Decline',
        ),
        CustomButton(
          onPressed: () {
            Navigator.pop(context);
            if (onAccept != null) {
              onAccept!();
            }
          },
          title: 'Accept',
        ),
      ],
    );
  }
}
