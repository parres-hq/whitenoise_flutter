import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';

class StartSecureChatBottomSheet extends StatelessWidget {
  final String name;
  final String nip05;
  final String? bio;
  final String? imagePath;
  final VoidCallback? onStartChat;
  const StartSecureChatBottomSheet({
    super.key,
    required this.name,
    required this.nip05,
    this.bio,
    this.imagePath,
    this.onStartChat,
  });

  static Future<void> show({
    required BuildContext context,
    required String name,
    required String nip05,
    String? bio,
    String? imagePath,
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
            nip05: nip05,
            bio: bio,
            imagePath: imagePath,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(40.r),
                child: Container(
                  width: 80.w,
                  height: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                  child:
                      imagePath != null && imagePath!.isNotEmpty
                          ? Image.network(
                            imagePath!,
                            width: 80.w,
                            height: 80.w,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                          )
                          : Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ),
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
              if (bio != null && bio!.isNotEmpty) ...[
                Gap(8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.colors.mutedForeground,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              Gap(48.h),
            ],
          ),
        ),
        AppFilledButton(
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
