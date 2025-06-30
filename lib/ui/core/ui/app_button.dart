import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

part 'app_filled_button.dart';
part 'app_text_button.dart';

const kMinimumButtonSize = Size(358, 56);
const kMinimumSmallButtonSize = Size(358, 44);

enum AppButtonSize {
  large(kMinimumButtonSize),
  small(kMinimumSmallButtonSize);

  final Size value;
  const AppButtonSize(this.value);

  TextStyle textStyle() {
    return switch (this) {
      AppButtonSize.large => TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      ),
      AppButtonSize.small => TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
      ),
    };
  }
}

enum AppButtonVisualState {
  primary,
  secondary,
  tertiary,
  success,
  warning,
  error;

  Color backgroundColor(BuildContext context) {
    final colors = context.colors;

    return switch (this) {
      AppButtonVisualState.error => colors.destructive,
      AppButtonVisualState.success => colors.success,
      AppButtonVisualState.warning => colors.warning,
      AppButtonVisualState.primary => colors.primary,
      AppButtonVisualState.secondary => colors.secondary,
      AppButtonVisualState.tertiary => colors.tertiary,
    };
  }

  Color foregroundColor(BuildContext context) {
    final colors = context.colors;

    return switch (this) {
      AppButtonVisualState.error => colors.primaryForeground,
      AppButtonVisualState.success => colors.primaryForeground,
      AppButtonVisualState.warning => colors.primaryForeground,
      AppButtonVisualState.primary => colors.primaryForeground,
      AppButtonVisualState.secondary => colors.secondaryForeground,
      AppButtonVisualState.tertiary => colors.secondaryForeground,
    };
  }

  Color disabledBackgroundColor(BuildContext context) {
    final colors = context.colors;
    return switch (this) {
      AppButtonVisualState.error => colors.destructive.withValues(alpha: 0.5),
      AppButtonVisualState.success => colors.success.withValues(alpha: 0.5),
      AppButtonVisualState.warning => colors.warning.withValues(alpha: 0.5),
      AppButtonVisualState.primary => colors.primary.withValues(alpha: 0.5),
      AppButtonVisualState.secondary => colors.warning.withValues(
        alpha: 0.5,
      ),
      AppButtonVisualState.tertiary => colors.tertiary.withValues(
        alpha: 0.5,
      ),
    };
  }

  Color disabledForegroundColor(BuildContext context) {
    final colors = context.colors;
    AppColors.glitch50;
    return switch (this) {
      AppButtonVisualState.error => colors.primaryForeground,
      AppButtonVisualState.success => colors.primaryForeground,
      AppButtonVisualState.warning => colors.primaryForeground,
      AppButtonVisualState.primary => colors.primaryForeground,
      AppButtonVisualState.secondary => colors.secondaryForeground,
      AppButtonVisualState.tertiary => colors.secondaryForeground,
    };
  }

  Color borderColor(BuildContext context) {
    final colors = context.colors;
    return switch (this) {
      AppButtonVisualState.secondary => colors.border,
      AppButtonVisualState.tertiary => Colors.transparent,
      AppButtonVisualState.primary => Colors.transparent,
      AppButtonVisualState.success => Colors.transparent,
      AppButtonVisualState.warning => Colors.transparent,
      AppButtonVisualState.error => Colors.transparent,
    };
  }
}

sealed class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.style,
    this.icon,
    this.onLongPress,
    required this.child,
    required this.onPressed,
    this.ignorePointer = false,
    this.size = AppButtonSize.large,
    this.iconAlignment = IconAlignment.start,
    this.visualState = AppButtonVisualState.primary,
  });

  final Widget child;
  final Widget? icon;
  final bool ignorePointer;
  final AppButtonSize size;
  final ButtonStyle? style;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final IconAlignment iconAlignment;
  final AppButtonVisualState visualState;

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
  const ButtonLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18.w,
      child: CircularProgressIndicator(
        strokeCap: StrokeCap.round,
        strokeWidth: 2.w,
      ),
    );
  }
}
