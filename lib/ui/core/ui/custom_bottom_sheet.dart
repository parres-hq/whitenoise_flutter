import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';

import '../themes/src/extensions.dart';

/// A utility class for showing custom bottom sheets with a smooth slide-up animation.
class CustomBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    String? title,
    bool showCloseButton = true,
    bool showBackButton = false,
    double heightFactor = 0.9,
    bool wrapContent = false,
    double? maxHeight,
    bool barrierDismissible = true,
    String? barrierLabel,
    bool blurBackground = true,
    double blurSigma = 10.0,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
    bool keyboardAware = false,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ?? 'BottomSheet',
      barrierColor: context.colors.bottomSheetBarrier,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink(); // This won't be used
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final bottomSheetHeight = wrapContent ? null : 1.sh * heightFactor;
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        // Create an animated blur effect
        final blurAnimation = Tween<double>(
          begin: 0.0,
          end: blurSigma,
        ).animate(curvedAnimation);

        // Create an animated opacity for the barrier
        final barrierOpacityAnimation = Tween<double>(
          begin: 0.0,
          end: 0.5, // Semi-transparent barrier
        ).animate(curvedAnimation);

        // Create a slide animation for the bottom sheet
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curvedAnimation);

        return Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Animated barrier
              AnimatedBuilder(
                animation: barrierOpacityAnimation,
                builder: (context, child) {
                  return GestureDetector(
                    onTap: barrierDismissible ? () => Navigator.of(context).pop() : null,
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: barrierOpacityAnimation.value,
                      ),
                    ),
                  );
                },
              ),

              // Positioned bottom sheet with slide animation
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedBuilder(
                      animation: slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                            0,
                            wrapContent
                                ? (1.sh * slideAnimation.value.dy)
                                : (bottomSheetHeight! * slideAnimation.value.dy),
                          ),
                          child: child,
                        );
                      },
                      child:
                          blurBackground
                              ? AnimatedBuilder(
                                animation: blurAnimation,
                                builder: (context, child) {
                                  return BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: blurAnimation.value,
                                      sigmaY: blurAnimation.value,
                                    ),
                                    child: child,
                                  );
                                },
                                child: _buildBottomSheetContent(
                                  context: context,
                                  builder: builder,
                                  title: title,
                                  showCloseButton: showCloseButton,
                                  showBackButton: showBackButton,
                                  bottomSheetHeight: bottomSheetHeight,
                                  wrapContent: wrapContent,
                                  maxHeight: maxHeight,
                                  backgroundColor: context.colors.neutral,
                                  keyboardAware: keyboardAware,
                                ),
                              )
                              : _buildBottomSheetContent(
                                context: context,
                                builder: builder,
                                title: title,
                                showCloseButton: showCloseButton,
                                showBackButton: showBackButton,
                                bottomSheetHeight: bottomSheetHeight,
                                wrapContent: wrapContent,
                                maxHeight: maxHeight,
                                backgroundColor: context.colors.neutral,
                                keyboardAware: keyboardAware,
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildBottomSheetContent({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    required double? bottomSheetHeight,
    required bool wrapContent,
    required Color backgroundColor,
    double? maxHeight,
    String? title,
    bool showCloseButton = true,
    bool showBackButton = false,
    bool keyboardAware = false,
  }) {
    final contentWidget = Column(
      mainAxisSize: wrapContent ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (title != null || showCloseButton || showBackButton)
          Padding(
            padding: EdgeInsets.fromLTRB(showBackButton ? 8.w : 24.w, 16.h, 16.w, 24.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (showBackButton) ...[
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            CarbonIcons.chevron_left,
                            color: context.colors.primary,
                            size: 24.w,
                          ),
                        ),
                        Gap(8.w),
                      ],
                      if (title != null)
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: context.colors.mutedForeground,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (showCloseButton)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: context.colors.primary,
                      size: 24.w,
                    ),
                  ),
              ],
            ),
          ),
        wrapContent ? Flexible(child: builder(context)) : Expanded(child: builder(context)),
        if (Platform.isAndroid) Gap(40.h) else Gap(16.h),
      ],
    );

    if (wrapContent) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? 1.sh * 0.9, // Default max height
        ),
        decoration: BoxDecoration(color: backgroundColor),
        child:
            keyboardAware
                ? Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: contentWidget,
                )
                : contentWidget,
      );
    } else {
      return Container(
        height: bottomSheetHeight!,
        decoration: BoxDecoration(color: backgroundColor),
        child:
            keyboardAware
                ? Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: contentWidget,
                )
                : contentWidget,
      );
    }
  }
}
