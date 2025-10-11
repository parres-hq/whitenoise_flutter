import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class EmptyChatWidget extends StatelessWidget {
  const EmptyChatWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const WnImage(AssetsPaths.icChat),
          Gap(20.h),
          Text(
            'chats.noChatsFound'.tr(),
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontSize: 18.sp,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Text(
            'chats.startNewChat'.tr(),
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontSize: 18.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
