import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A utility class for showing custom bottom sheets with a smooth slide-up animation.
class CustomBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    String? title,
    bool showCloseButton = true,
    double heightFactor = 0.9,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = Colors.black54,
    Color backgroundColor = Colors.white,
    bool blurBackground = true,
    double blurSigma = 5.0,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutCubic,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ?? 'BottomSheet',
      barrierColor: Colors.transparent, // We'll handle our own barrier
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink(); // This won't be used
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final bottomSheetHeight = 1.sh * heightFactor;
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
                    onTap: barrierDismissible 
                        ? () => Navigator.of(context).pop() 
                        : null,
                    child: Container(
                      color: Colors.black.withValues(alpha:
                          barrierOpacityAnimation.value),
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
                            bottomSheetHeight * (1 - curvedAnimation.value),
                          ),
                          child: child,
                        );
                      },
                      child: blurBackground
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
                                bottomSheetHeight: bottomSheetHeight,
                                backgroundColor: backgroundColor,
                              ),
                            )
                          : _buildBottomSheetContent(
                              context: context,
                              builder: builder,
                              title: title,
                              showCloseButton: showCloseButton,
                              bottomSheetHeight: bottomSheetHeight,
                              backgroundColor: backgroundColor,
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
    required double bottomSheetHeight,
    required Color backgroundColor,
    String? title,
    bool showCloseButton = true,
  }) {
    return Container(
      height: bottomSheetHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        children: [
          // Add a visible drag handle
          Container(
            margin: EdgeInsets.only(top: 8.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          if (title != null || showCloseButton)
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 16.w, 24.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const Spacer(),
                  if (showCloseButton)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 24.w,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(child: builder(context)),
        ],
      ),
    );
  }
}
