import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/profile/edit_profile_screen.dart';

class ChatInvitationSheet extends StatelessWidget {
  final String name;
  final String nip05;
  final String publicKey;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const ChatInvitationSheet({
    super.key,
    required this.name,
    required this.nip05,
    required this.publicKey,
    this.onAccept,
    this.onDecline,
  });

  static Future<void> show({
    required BuildContext context,
    required String name,
    required String nip05,
    required String publicKey,
    VoidCallback? onAccept,
    VoidCallback? onDecline,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Invitation to join secure chat',
      heightFactor: 0.65,
      blurSigma: 8.0,
      transitionDuration: const Duration(milliseconds: 400),
      builder:
          (context) => ChatInvitationSheet(
            name: name,
            nip05: nip05,
            publicKey: publicKey,
            onAccept: onAccept,
            onDecline: onDecline,
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
              Gap(24.h),
              FallbackProfileImageWidget(
                displayName: name,
              ),
              Gap(12.h),
              Text(
                name,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w500,
                  color: context.colors.primary,
                ),
              ),
              Gap(12.h),
              Text(
                nip05,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
              Gap(8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  publicKey,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.mutedForeground,
                  ),
                ),
              ),
              Gap(48.h),
            ],
          ),
        ),
        const Spacer(),
        AppFilledButton(
          visualState: AppButtonVisualState.secondary,
          onPressed: () {
            Navigator.pop(context);
            if (onDecline != null) {
              onDecline!();
            }
          },
          title: 'Decline',
        ),
        AppFilledButton(
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
