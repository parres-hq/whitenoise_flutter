import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/src/colors.dart';
import 'package:whitenoise/ui/core/themes/src/dimensions.dart';
import 'package:whitenoise/ui/core/themes/src/light/light.dart';

extension TextStyleExtension on TextStyle {
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);

  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);

  /// Returns the TextStyle with the `color` property
  /// set to `context.colors.inputText`
  TextStyle input(BuildContext context) {
    return copyWith(color: context.colors.mutedForeground);
  }

  /// Returns the TextStyle with the `color` property
  /// set to `context.colors.headerText`
  TextStyle header(BuildContext context) {
    return copyWith(color: context.colors.secondaryForeground);
  }

  /// Returns the TextStyle with the `color` property
  /// set to `context.colors.neutral`
  TextStyle neutral(BuildContext context) {
    return copyWith(color: context.colors.neutral);
  }

  /// Returns the TextStyle with the `color` property
  /// set to `context.colors.primary`
  TextStyle primary(BuildContext context) {
    return copyWith(color: context.colors.primary);
  }

  /// Returns the TextStyle with the `color` property
  /// set to `context.colors.warning`
  TextStyle warning(BuildContext context) {
    return copyWith(color: context.colors.warning);
  }

  /// Returns the TextStyle with the `color` property
  /// set to `context.colors.error`
  TextStyle error(BuildContext context) {
    return copyWith(color: context.colors.destructive);
  }
}

extension BuildContextExtension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  AppColorsThemeExt get colors => Theme.of(this).extension<AppColorsThemeExt>() ?? lightColorsExt;
  AppDimension get dimensions => Theme.of(this).extension<AppDimension>() ?? AppDimension();
}
