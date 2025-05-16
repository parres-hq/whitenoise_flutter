
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/core/utils/app_colors.dart';
import 'package:whitenoise/core/utils/assets_paths.dart';
import 'package:whitenoise/features/contact_list/presentation/search_screen.dart';

class ChatListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.color202320,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: SafeArea(
          child: Row(
            children: [
              Image.asset(AssetsPaths.icImage, width: 32.w, height: 32.w),
              const Spacer(),
              GestureDetector(
                onTap: () => SearchBottomSheet.show(context),
                child: SvgPicture.asset(AssetsPaths.icSearch),
              ),
              Gap(24.w),
              SvgPicture.asset(AssetsPaths.icAdd),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}
