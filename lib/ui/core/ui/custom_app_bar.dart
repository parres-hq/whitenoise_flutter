import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.glitch950,
      automaticallyImplyLeading: false,
      toolbarHeight: 64.h,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(Routes.contacts);
                }
              },
              child: const Icon(Icons.arrow_back, color: AppColors.white),
            ),
            Gap(16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}
