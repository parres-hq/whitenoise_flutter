import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/search_chat_bottom_sheet.dart';

class ChatListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSettingsTap;

  const ChatListAppBar({super.key, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
    ));

    return ColoredBox(
      color: AppColors.glitch950,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: SafeArea(
          child: Row(
            children: [
              GestureDetector(
                onTap: onSettingsTap ?? () => context.push(Routes.settings),
                child: Image.asset(
                  AssetsPaths.icImage,
                  width: 32.w,
                  height: 32.w,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => SearchChatBottomSheet.show(context),
                child: SvgPicture.asset(AssetsPaths.icSearch),
              ),
              Gap(24.w),
              GestureDetector(
                onTap: () => NewChatBottomSheet.show(context),
                child: SvgPicture.asset(
                  AssetsPaths.icAdd,
                  colorFilter: ColorFilter.mode(AppColors.glitch50, BlendMode.srcIn),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}
