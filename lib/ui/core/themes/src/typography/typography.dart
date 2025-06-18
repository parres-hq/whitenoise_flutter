import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/colors.dart';

part 'constants.dart';
part 'extension.dart';

final lightTextTheme = baseTextTheme.apply(
  bodyColor: LightAppColors.mutedForeground,
  displayColor: LightAppColors.textDefaultSecondary,
);

final darkTextTheme = baseTextTheme.apply(
  bodyColor: DarkAppColors.mutedForeground,
  displayColor: DarkAppColors.textDefaultSecondary,
);

final baseTextTheme = TextTheme(
  displayLarge: TextStyle(
    fontSize: 50.sp,
    height: 55 / 50,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  displayMedium: TextStyle(
    fontSize: 40.sp,
    height: 45 / 40,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  displaySmall: TextStyle(
    fontSize: 36.sp,
    height: 40 / 36,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),

  // Headline
  headlineLarge: TextStyle(
    fontSize: 32.sp,
    height: 35 / 32,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  headlineMedium: TextStyle(
    fontSize: 28.sp,
    height: 30 / 28,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  headlineSmall: TextStyle(
    fontSize: 24.sp,
    height: 28 / 24,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),

  // Title
  titleLarge: TextStyle(
    fontSize: 22.sp,
    height: 26 / 22,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  titleMedium: TextStyle(
    fontSize: 15.sp,
    height: 20 / 16,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  titleSmall: TextStyle(
    fontSize: 14.sp,
    height: 16 / 14,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),

  // Body
  bodyLarge: TextStyle(
    fontSize: 16.sp,
    height: 20 / 16,
    fontWeight: regular,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  bodyMedium: TextStyle(
    fontSize: 14.sp,
    height: 18 / 14,
    fontWeight: regular,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  bodySmall: TextStyle(
    fontSize: 12.sp,
    height: 16 / 12,
    fontWeight: regular,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),

  // Label
  labelLarge: TextStyle(
    fontSize: 14.sp,
    height: 18 / 14,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  labelMedium: TextStyle(
    fontSize: 12.sp,
    height: 16 / 12,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
    fontFamily: manropeFontFamily,
  ),
  labelSmall: TextStyle(
    fontSize: 11.sp,
    height: 14 / 11,
    fontWeight: semiBold,
    letterSpacing: letterSpacing,
  ),
);
