import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

import 'package:whitenoise/utils/localization_extensions.dart';

class CameraPermissionDeniedWidget extends StatelessWidget {
  const CameraPermissionDeniedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'permissions.cameraDenied'.tr(),
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gap(8.h),
          GestureDetector(
            onTap: () => openAppSettings(),
            child: Text(
              'permissions.openSettings'.tr(),
              style: TextStyle(
                color: context.colors.primary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
