import 'package:flutter/material.dart';

class LightAppColors {
  /// base/primary, custom colors/glitch-950
  static const primary = Color(0xff202320);

  /// base/secondary
  static const secondary = Color(0xffF2F2F2);
  static const tertiary = Color(0xFFE9F1FE);
  static const neutral = Color(0xFFFFFFFF);
  static const neutralVariant = Color(0xFF5A605A);

  /// base/background
  static const primaryForeground = Color(0xffF9F9F9);

  /// base/accent-foreground, base/secondary-foreground, base/foreground
  static const secondaryForeground = Color(0xff2D312D);

  /// base/muted-foreground
  static const mutedForeground = Color(0xFF727772);

  /// base/muted, base/input
  static const baseMuted = Color(0xffE2E2E2);

  /// Text/Default/Secondary
  static const textDefaultSecondary = Color(0xff757575);

  static const success = Color(0xFF2EA970);

  /// base/destructive
  static const destructive = Color(0xFFDC2626);

  /// base/warning
  static const warning = Color(0xffEA580C);

  static const baseChat = Color(0xff2A9D90);
  static const baseChat2 = Color(0xffE76E50);
  static const teal200 = Color(0xff99F6E4);
  static const teal600 = Color(0xFF0D9488);

  /// tailwind colors/rose/500
  static const rose = Color(0xFFF43F5E);

  /// tailwind colors/lime/500
  static const lime = Color(0xff84CC16);

  /// app bar color
  static const appBarBackground = Color(0xff000000);

  /// app bar text color
  static const appBarForeground = Color(0xffffffff);

  /// bottom sheet barrier color
  static const bottomSheetBarrier = Color(0x0FFFFFFF);
}

/// Dark theme colors
class DarkAppColors {
  /// base/primary, Custom inverted for dark mode
  static const primary = Color(0xffF9F9F9);

  /// base/secondary
  static const secondary = Color(0xff202320);
  static const tertiary = Color(0xFF1A2B4B);
  static const neutral = Color(0xFF000000);
  static const neutralVariant = Color(0xFF5A605A);

  /// base/background
  static const primaryBackground = Color(0xff2D312D);

  /// base/accent-foreground, base/secondary-foreground, base/foreground
  static const secondaryForeground = Color(0xffF2F2F2);

  /// base/muted-foreground
  static const mutedForeground = Color(0xFF727772);

  /// base/muted, base/input
  static const baseMuted = Color(0xff474C47);

  /// Text/Default/Secondary
  static const textDefaultSecondary = Color(0xffCDCECD);

  static const success = Color(0xFF4ADE80);

  /// base/destructive
  static const destructive = Color(0xFFEF4444);

  /// base/warning
  static const warning = Color(0xffF97316);

  static const baseChat = Color(0xff2A9D90);
  static const baseChat2 = Color(0xffE76E50);
  static const teal200 = Color(0xff99F6E4);
  static const teal600 = Color(0xFF0D9488);

  /// tailwind colors/rose/500
  static const rose = Color(0xFFF43F5E);

  /// tailwind colors/lime/500
  static const lime = Color(0xff84CC16);

  /// app bar color
  static const appBarBackground = Color(0xff171717);

  /// app bar text color
  static const appBarForeground = Color(0xffffffff);

  /// bottom sheet barrier color
  static const bottomSheetBarrier = Color(0x0FFFFFFF);
}

class AppColorsThemeExt extends ThemeExtension<AppColorsThemeExt> {
  const AppColorsThemeExt({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.neutral,
    required this.neutralVariant,
    required this.primaryForeground,
    required this.secondaryForeground,
    required this.mutedForeground,
    required this.baseMuted,
    required this.textDefaultSecondary,
    required this.success,
    required this.destructive,
    required this.warning,
    required this.baseChat,
    required this.baseChat2,
    required this.teal200,
    required this.teal600,
    required this.rose,
    required this.lime,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.bottomSheetBarrier,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color neutral;
  final Color neutralVariant;
  final Color primaryForeground;
  final Color secondaryForeground;
  final Color mutedForeground;
  final Color baseMuted;
  final Color textDefaultSecondary;
  final Color success;
  final Color destructive;
  final Color warning;
  final Color baseChat;
  final Color baseChat2;
  final Color teal200;
  final Color teal600;
  final Color rose;
  final Color lime;
  final Color appBarBackground;
  final Color appBarForeground;
  final Color bottomSheetBarrier;
  /// Light theme colors
  static AppColorsThemeExt get light => const AppColorsThemeExt(
    primary: LightAppColors.primary,
    secondary: LightAppColors.secondary,
    tertiary: LightAppColors.tertiary,
    neutral: LightAppColors.neutral,
    neutralVariant: LightAppColors.neutralVariant,
    primaryForeground: LightAppColors.primaryForeground,
    secondaryForeground: LightAppColors.secondaryForeground,
    mutedForeground: LightAppColors.mutedForeground,
    baseMuted: LightAppColors.baseMuted,
    textDefaultSecondary: LightAppColors.textDefaultSecondary,
    success: LightAppColors.success,
    destructive: LightAppColors.destructive,
    warning: LightAppColors.warning,
    baseChat: LightAppColors.baseChat,
    baseChat2: LightAppColors.baseChat2,
    teal200: LightAppColors.teal200,
    teal600: LightAppColors.teal600,
    rose: LightAppColors.rose,
    lime: LightAppColors.lime,
    appBarBackground: LightAppColors.appBarBackground,
    appBarForeground: LightAppColors.appBarForeground,
    bottomSheetBarrier: LightAppColors.bottomSheetBarrier,
  );

  /// Dark theme colors
  static AppColorsThemeExt get dark => const AppColorsThemeExt(
    primary: DarkAppColors.primary,
    secondary: DarkAppColors.secondary,
    tertiary: DarkAppColors.tertiary,
    neutral: DarkAppColors.neutral,
    neutralVariant: DarkAppColors.neutralVariant,
    primaryForeground: DarkAppColors.primaryBackground,
    secondaryForeground: DarkAppColors.secondaryForeground,
    mutedForeground: DarkAppColors.mutedForeground,
    baseMuted: DarkAppColors.baseMuted,
    textDefaultSecondary: DarkAppColors.textDefaultSecondary,
    success: DarkAppColors.success,
    destructive: DarkAppColors.destructive,
    warning: DarkAppColors.warning,
    baseChat: DarkAppColors.baseChat,
    baseChat2: DarkAppColors.baseChat2,
    teal200: DarkAppColors.teal200,
    teal600: DarkAppColors.teal600,
    rose: DarkAppColors.rose,
    lime: DarkAppColors.lime,
    appBarBackground: DarkAppColors.appBarBackground,
    appBarForeground: DarkAppColors.appBarForeground,
    bottomSheetBarrier: DarkAppColors.bottomSheetBarrier,
  );

  @override
  AppColorsThemeExt copyWith({
    Color? primary,
    Color? secondary,
    Color? tertiary,
    Color? neutral,
    Color? neutralVariant,
    Color? primaryForeground,
    Color? secondaryForeground,
    Color? mutedForeground,
    Color? baseMuted,
    Color? textDefaultSecondary,
    Color? success,
    Color? destructive,
    Color? warning,
    Color? baseChat,
    Color? baseChat2,
    Color? teal200,
    Color? teal600,
    Color? rose,
    Color? lime,
    Color? appBarBackground,
    Color? appBarForeground,
    Color? bottomSheetBarrier,
  }) {
    return AppColorsThemeExt(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      neutral: neutral ?? this.neutral,
      neutralVariant: neutralVariant ?? this.neutralVariant,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      baseMuted: baseMuted ?? this.baseMuted,
      textDefaultSecondary: textDefaultSecondary ?? this.textDefaultSecondary,
      success: success ?? this.success,
      destructive: destructive ?? this.destructive,
      warning: warning ?? this.warning,
      baseChat: baseChat ?? this.baseChat,
      baseChat2: baseChat2 ?? this.baseChat2,
      teal200: teal200 ?? this.teal200,
      teal600: teal600 ?? this.teal600,
      rose: rose ?? this.rose,
      lime: lime ?? this.lime,
      appBarBackground: appBarBackground ?? this.appBarBackground,
      appBarForeground: appBarForeground ?? this.appBarForeground,
      bottomSheetBarrier: bottomSheetBarrier ?? this.bottomSheetBarrier,
    );
  }

  @override
  AppColorsThemeExt lerp(covariant AppColorsThemeExt? other, double t) {
    if (other == null) return this;
    return AppColorsThemeExt(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      neutralVariant: Color.lerp(neutralVariant, other.neutralVariant, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondaryForeground:
          Color.lerp(
            secondaryForeground,
            other.secondaryForeground,
            t,
          )!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      baseMuted: Color.lerp(baseMuted, other.baseMuted, t)!,
      textDefaultSecondary:
          Color.lerp(
            textDefaultSecondary,
            other.textDefaultSecondary,
            t,
          )!,
      success: Color.lerp(success, other.success, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      baseChat: Color.lerp(baseChat, other.baseChat, t)!,
      baseChat2: Color.lerp(baseChat2, other.baseChat2, t)!,
      teal200: Color.lerp(teal200, other.teal200, t)!,
      teal600: Color.lerp(teal600, other.teal600, t)!,
      rose: Color.lerp(rose, other.rose, t)!,
      lime: Color.lerp(lime, other.lime, t)!,
      appBarBackground: Color.lerp(appBarBackground, other.appBarBackground, t)!,
      appBarForeground: Color.lerp(appBarForeground, other.appBarForeground, t)!,
      bottomSheetBarrier: Color.lerp(bottomSheetBarrier, other.bottomSheetBarrier, t)!,
    );
  }
}
