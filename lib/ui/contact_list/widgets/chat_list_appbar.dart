import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/search_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class ChatListAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onSettingsTap;

  const ChatListAppBar({super.key, this.onSettingsTap});

  @override
  State<ChatListAppBar> createState() => _ChatListAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}

class _ChatListAppBarState extends State<ChatListAppBar> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.appBarBackground,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: SafeArea(
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onSettingsTap ?? () => context.push(Routes.settings),
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
                    context.colors.appBarForeground,
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
}
