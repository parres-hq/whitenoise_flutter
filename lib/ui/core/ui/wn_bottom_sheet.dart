import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

/// Custom page route for bottom sheets with fade animation for background overlay
class _FadeBottomSheetRoute<T> extends PageRoute<T> {
  final Widget Function(BuildContext) builder;
  final bool _barrierDismissible;
  final String? _barrierLabel;
  final Duration _transitionDuration;
  final Curve curve;

  _FadeBottomSheetRoute({
    required this.builder,
    bool barrierDismissible = true,
    String? barrierLabel,
    Duration transitionDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    super.settings,
  }) : _barrierDismissible = barrierDismissible,
       _barrierLabel = barrierLabel,
       _transitionDuration = transitionDuration;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => _barrierDismissible;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  bool get maintainState => true;

  @override
  Color get barrierColor => Colors.black.withValues(alpha: 0.3);

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade animation for the background overlay
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
    );

    // Slide animation for the bottom sheet content
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: curve,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Fading background overlay
            FadeTransition(
              opacity: fadeAnimation,
              child: Container(
                color: context.colors.bottomSheetBarrier,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Sliding bottom sheet content
            SlideTransition(
              position: slideAnimation,
              child: child!,
            ),
          ],
        );
      },
      child: child,
    );
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }
}

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
    bool useSafeArea = true,
  }) {
    return Navigator.of(context).push<T>(
      _FadeBottomSheetRoute<T>(
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel ?? 'BottomSheet',
        transitionDuration: transitionDuration,
        curve: curve,
        builder:
            (BuildContext context) => GestureDetector(
              onTap: barrierDismissible ? () => Navigator.of(context).pop() : null,
              behavior: HitTestBehavior.opaque,
              child: Stack(
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
                    child: GestureDetector(
                      onTap: () {}, // Prevent tap from propagating to background
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
                              maxHeight:
                                  MediaQuery.sizeOf(context).height -
                                  MediaQuery.paddingOf(context).top,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w).copyWith(
                                bottom:
                                    (keyboardAware ? MediaQuery.viewInsetsOf(context).bottom : 0) +
                                    (useSafeArea ? _calculateBottomPadding(context) : 0),
                                top: 16.h,
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
                  ),
                ],
              ),
            ),
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
              size: 32.w,
            ),
          ),
      ],
    );
  }
}
