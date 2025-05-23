import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/search_chat_bottom_sheet.dart';

class ChatListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure status bar has light icons on this dark background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // for Android
      statusBarBrightness: Brightness.dark, // for iOS
    ));
    
    return ColoredBox(
      color: AppColors.glitch950,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: SafeArea(
          child: Row(
            children: [
              Image.asset(AssetsPaths.icImage, width: 32.w, height: 32.w),
              const Spacer(),
              GestureDetector(
                onTap: () => SearchChatBottomSheet.show(context),
                child: SvgPicture.asset(AssetsPaths.icSearch),
              ),
              Gap(24.w),
              GestureDetector(
                onTap: () => NewChatBottomSheet.show(context),
                child: SvgPicture.asset(AssetsPaths.icAdd),
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
