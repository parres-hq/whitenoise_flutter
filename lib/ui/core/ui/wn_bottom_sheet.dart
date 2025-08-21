import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

import '../themes/assets.dart';
import '../themes/src/extensions.dart';

/// A utility class for showing custom bottom sheets with a smooth slide-up animation.
class WnBottomSheet {
  /// Helper method to check if keyboard is currently open
  static bool isKeyboardOpen(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Calculate bottom padding to reach exactly 24h or 54h total (including SafeArea)
  static double _calculateBottomPadding(BuildContext context) {
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    final targetPadding = isKeyboardOpen(context) ? 24.h : 54.h;
    final additionalPadding = targetPadding - safeAreaBottom;

    // Ensure we don't have negative padding
    return additionalPadding > 0 ? additionalPadding : 0;
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    String? title,
    bool showCloseButton = true,
    bool showBackButton = false,
    bool barrierDismissible = true,
    String? barrierLabel,
    bool blurBackground = true,
    double blurSigma = 10.0,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
    bool keyboardAware = false,
    bool isScrollControlled = true,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: barrierDismissible,
      barrierLabel: barrierLabel ?? 'BottomSheet',
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: context.colors.bottomSheetBarrier,
      builder:
          (BuildContext context) => Stack(
            children: [
              if (blurBackground)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.primaryForeground,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        // Ensure the bottom sheet stops before the status bar area
                        // Using design system specification: 54 for status bar height
                        maxHeight: MediaQuery.of(context).size.height - 54.h,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(
                          bottom:
                              useSafeArea
                                  ? MediaQuery.viewInsetsOf(context).bottom.h +
                                      _calculateBottomPadding(context)
                                  : MediaQuery.viewInsetsOf(context).bottom.h,
                          top: 21.h,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (title != null || showCloseButton || showBackButton)
                              _buildBottomSheetHeader(
                                showBackButton,
                                context,
                                title,
                                showCloseButton,
                              ),
                            Gap(25.h),
                            Flexible(child: builder(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// Builds the header for the bottom sheet, including a back button, title, and close button.
  static Row _buildBottomSheetHeader(
    bool showBackButton,
    BuildContext context,
    String? title,
    bool showCloseButton,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              if (showBackButton) ...[
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: WnImage(
                    AssetsPaths.icChevronLeft,
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
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        if (showCloseButton)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: WnImage(
              AssetsPaths.icClose,
              color: context.colors.primary,
              size: 24.w,
            ),
          ),
      ],
    );
  }
}
