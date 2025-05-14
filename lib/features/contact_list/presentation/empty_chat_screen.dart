import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/core/utils/app_colors.dart';
import 'package:whitenoise/core/utils/assets_paths.dart';
import 'package:whitenoise/features/contact_list/presentation/widgets/contact_list_appbar.dart';

class EmptyChatScreen extends StatelessWidget {
  const EmptyChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: AppColors.color202320,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const ContactListAppBar(),
      ),
      body: ColoredBox(
        color: AppColors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AssetsPaths.icChat,
              ),
              Gap(20.h),
              Text(
                'No chats found\nClick "+" to start a new chat',
                style: TextStyle(
                  color: AppColors.color727772,
                  fontSize: 18.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
