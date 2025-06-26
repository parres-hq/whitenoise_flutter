import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/settings/widgets/theme_toggle_icon_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.showThemeToggle = true,
  });

  final String title;
  final bool showThemeToggle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.appBarBackground,
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
              child: Icon(Icons.arrow_back, color: context.colors.appBarForeground),
            ),
            Gap(16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: context.colors.appBarForeground,
                ),
              ),
            ),
            if (showThemeToggle) const ThemeToggleIconButton(),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}
