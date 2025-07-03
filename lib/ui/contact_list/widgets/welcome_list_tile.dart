import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WelcomeListTile extends StatelessWidget {
  final WelcomeData welcomeData;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const WelcomeListTile({
    super.key,
    required this.welcomeData,
    this.onTap,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24.r,
          backgroundImage: const AssetImage(AssetsPaths.icImage),
          child: Icon(
            Icons.group,
            size: 20.r,
            color: context.colors.primary,
          ),
        ),
        title: Text(
          welcomeData.groupName,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: context.colors.primary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap(4.h),
            Text(
              'Invited by ${welcomeData.welcomer}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.colors.mutedForeground,
              ),
            ),
            Gap(2.h),
            Text(
              '${welcomeData.memberCount} members',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.colors.mutedForeground,
              ),
            ),
            Gap(8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDecline,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                ),
                Gap(8.w),
                TextButton(
                  onPressed: onAccept,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    'Accept',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
