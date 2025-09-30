import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AuthAppBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final fadeHeight = 48.h;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: preferredSize.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: WnImage(
                        AssetsPaths.icChevronLeft,
                        size: 18.w,
                        color: context.colors.primary,
                      ),
                    ),
                    Gap(8.w),
                    Flexible(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colors.mutedForeground,
                        ),
                        textHeightBehavior: const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                          applyHeightToLastDescent: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              // +1 here to overcome the tiny line showing between the appBar and the fade on iOS
              // no noticeable difference on Android, so no need to do a platform check to apply to iOS only.
              bottom: -fadeHeight + 1,
              child: IgnorePointer(
                child: Container(
                  height: fadeHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        context.colors.neutral.withValues(alpha: 0.99),
                        context.colors.neutral.withValues(alpha: 0.9),
                        context.colors.neutral.withValues(alpha: 0.79),
                        context.colors.neutral.withValues(alpha: 0.7),
                        context.colors.neutral.withValues(alpha: 0.59),
                        context.colors.neutral.withValues(alpha: 0.5),
                        context.colors.neutral.withValues(alpha: 0.39),
                        context.colors.neutral.withValues(alpha: 0.29),
                        context.colors.neutral.withValues(alpha: 0.19),
                        context.colors.neutral.withValues(alpha: 0.09),
                        context.colors.neutral.withValues(alpha: 0.05),
                        context.colors.neutral.withValues(alpha: 0.01),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}
