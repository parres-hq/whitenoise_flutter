import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

part 'wn_filled_button.dart';
part 'app_text_button.dart';

const kMinimumButtonSize = Size(358, 56);
const kMinimumSmallButtonSize = Size(358, 44);

enum WnButtonSize {
  large(kMinimumButtonSize),
  small(kMinimumSmallButtonSize);

  final Size value;
  const WnButtonSize(this.value);

  TextStyle textStyle() {
    return switch (this) {
      WnButtonSize.large => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
      WnButtonSize.small => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
    };
  }
}

enum WnButtonVisualState {
  primary,
  secondary,
  secondaryWarning,
  tertiary,
  success,
  warning,
  error;

  Color backgroundColor(BuildContext context) {
    final colors = context.colors;

    return switch (this) {
      WnButtonVisualState.error => colors.destructive,
      WnButtonVisualState.success => colors.success,
      WnButtonVisualState.warning => colors.warning,
      WnButtonVisualState.primary => colors.primary,
      WnButtonVisualState.secondary => colors.secondary,
      WnButtonVisualState.secondaryWarning => colors.destructive.withValues(alpha: 0.1),
      WnButtonVisualState.tertiary => colors.tertiary,
    };
  }

  Color foregroundColor(BuildContext context) {
    final colors = context.colors;

    return switch (this) {
      WnButtonVisualState.error => colors.primaryForeground,
      WnButtonVisualState.success => colors.primaryForeground,
      WnButtonVisualState.warning => colors.primaryForeground,
      WnButtonVisualState.primary => colors.primaryForeground,
      WnButtonVisualState.secondary => colors.secondaryForeground,
      WnButtonVisualState.secondaryWarning => colors.destructive,
      WnButtonVisualState.tertiary => colors.secondaryForeground,
    };
  }

  Color disabledBackgroundColor(BuildContext context) {
    final colors = context.colors;
    return switch (this) {
      WnButtonVisualState.error => colors.destructive.withValues(alpha: 0.5),
      WnButtonVisualState.success => colors.success.withValues(alpha: 0.5),
      WnButtonVisualState.warning => colors.warning.withValues(alpha: 0.5),
      WnButtonVisualState.primary => colors.primary.withValues(alpha: 0.5),
      WnButtonVisualState.secondary => colors.secondary.withValues(
        alpha: 0.5,
      ),
      WnButtonVisualState.secondaryWarning => colors.destructive.withValues(
        alpha: 0.5,
      ),
      WnButtonVisualState.tertiary => colors.tertiary.withValues(
        alpha: 0.5,
      ),
    };
  }

  Color disabledForegroundColor(BuildContext context) {
    final colors = context.colors;
    return switch (this) {
      WnButtonVisualState.error => colors.primaryForeground,
      WnButtonVisualState.success => colors.primaryForeground,
      WnButtonVisualState.warning => colors.primaryForeground,
      WnButtonVisualState.primary => colors.primaryForeground,
      WnButtonVisualState.secondary => colors.secondaryForeground,
      WnButtonVisualState.secondaryWarning => colors.destructive,
      WnButtonVisualState.tertiary => colors.secondaryForeground,
    };
  }

  Color borderColor(BuildContext context) {
    final colors = context.colors;
    return switch (this) {
      WnButtonVisualState.secondary => colors.border,
      WnButtonVisualState.tertiary => Colors.transparent,
      WnButtonVisualState.primary => Colors.transparent,
      WnButtonVisualState.success => Colors.transparent,
      WnButtonVisualState.warning => Colors.transparent,
      WnButtonVisualState.secondaryWarning => colors.destructive,
      WnButtonVisualState.error => Colors.transparent,
    };
  }
}

sealed class WnButton extends StatelessWidget {
  const WnButton({
    super.key,
    this.style,
    this.icon,
    this.onLongPress,
    required this.child,
    required this.onPressed,
    this.ignorePointer = false,
    this.size = WnButtonSize.large,
    this.iconAlignment = IconAlignment.start,
    this.visualState = WnButtonVisualState.primary,
  });

  final Widget child;
  final Widget? icon;
  final bool ignorePointer;
  final WnButtonSize size;
  final ButtonStyle? style;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final IconAlignment iconAlignment;
  final WnButtonVisualState visualState;

  Widget buildButton(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: ignorePointer,
      child: buildButton(context),
    );
  }
}

class ButtonLoadingIndicator extends StatelessWidget {
  const ButtonLoadingIndicator({super.key, this.color});
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final backgroundColor = color ?? context.colors.primaryForeground;
    return SizedBox.square(
      dimension: 18.w,
      child: CircularProgressIndicator(
        strokeCap: StrokeCap.round,
        strokeWidth: 2.w,
        backgroundColor: backgroundColor.withValues(alpha: 0.3),
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? context.colors.primaryForeground,
        ),
      ),
    );
  }
}
