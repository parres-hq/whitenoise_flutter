import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../themes/src/extensions.dart';

/// ```title``` is the title of the button
///
/// ```buttonType``` is the type of the button
///
/// ```child``` is the widget to be displayed if you desire to use a custom widget as title
class CustomFilledButton extends StatelessWidget {
  const CustomFilledButton({
    super.key,
    required this.onPressed,
    this.title,
    this.buttonType = ButtonType.primary,
    this.addPadding = true,
    this.horizontalPadding = 24.0,
    this.bottomPadding = 24.0,
    this.child,
  });

  final void Function()? onPressed;
  final String? title;
  final ButtonType buttonType;
  final bool addPadding;
  final double horizontalPadding;
  final double bottomPadding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isPrimary = buttonType == ButtonType.primary;
    final isSecondary = buttonType == ButtonType.secondary;
    final isTertiary = buttonType == ButtonType.tertiary;

    final button = SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor:
              isPrimary
                  ? context.colors.primary
                  : isSecondary
                  ? context.colors.secondary
                  : context.colors.warning,
          foregroundColor:
              isPrimary || isTertiary
                  ? context.colors.primaryForeground
                  : context.colors.secondaryForeground,
          disabledBackgroundColor:
              isPrimary
                  ? context.colors.primary.withValues(alpha: 0.5)
                  : isSecondary
                  ? context.colors.secondary
                  : context.colors.warning.withValues(alpha: 0.5),
          disabledForegroundColor:
              isPrimary
                  ? context.colors.primaryForeground
                  : context.colors.secondaryForeground,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: const RoundedRectangleBorder(),
        ),
        child:
            child ??
            Text(
              title ?? '',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
      ),
    );

    if (addPadding) {
      return Padding(
        padding: EdgeInsets.only(
          left: horizontalPadding.w,
          right: horizontalPadding.w,
          bottom: bottomPadding.h,
        ),
        child: button,
      );
    }
    return button;
  }
}

enum ButtonType { primary, secondary, tertiary }
