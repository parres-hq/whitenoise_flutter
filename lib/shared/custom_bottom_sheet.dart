import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A utility class for showing custom bottom sheets with a slide-up animation.
class CustomBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
    String? title,
    bool showCloseButton = true,
    double heightFactor = 0.9,
    bool barrierDismissible = true,
    String? barrierLabel,
    Color barrierColor = Colors.transparent,
    Color backgroundColor = Colors.white,
    bool blurBackground = true,
    double blurSigma = 5.0,
    Duration transitionDuration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOutQuad,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ?? 'BottomSheet',
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) {
        final bottomSheetHeight = 1.sh * heightFactor;

        return Material(
          color: Colors.transparent,
          child:
              blurBackground
                  ? BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
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
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curvedAnimation),
          child: child,
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black.withValues(alpha: 0.1)),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: bottomSheetHeight,
              decoration: BoxDecoration(color: backgroundColor),
              child: Column(
                children: [
                  if (title != null || showCloseButton)
                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 16.h, 16.w, 24.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (title != null)
                            Text(title, style: TextStyle(color: Colors.black, fontSize: 24.sp))
                          else
                            const Spacer(),
                          if (showCloseButton)
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(Icons.close, color: Colors.black, size: 24.w),
                            ),
                        ],
                      ),
                    ),
                  Expanded(child: builder(context)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
