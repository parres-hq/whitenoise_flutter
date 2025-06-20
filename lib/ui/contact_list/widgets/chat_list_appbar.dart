import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/themes/assets.dart';
import '../../core/themes/src/extensions.dart';
import '../new_chat_bottom_sheet.dart';
import '../search_chat_bottom_sheet.dart';

class ChatListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSettingsTap;

  const ChatListAppBar({super.key, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return ColoredBox(
      color: context.colors.primary,
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
                  colorFilter: ColorFilter.mode(
                    context.colors.primaryForeground,
                    BlendMode.srcIn,
                  ),
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
