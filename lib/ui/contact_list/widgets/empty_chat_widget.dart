import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

import '../../core/themes/assets.dart';
import '../../core/themes/src/extensions.dart';

class EmptyChatWidget extends StatelessWidget {
  const EmptyChatWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(AssetsPaths.icChat),
          Gap(20.h),
          Text(
            'No chats found',
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontSize: 18.sp,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(8.h),
          Text(
            'Click "+" to start a new chat',
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
