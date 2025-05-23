import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Glitch Colors
  static const Color glitch50 = Color(0xFFF9F9F9);
  static const Color glitch80 = Color(0xFFEEEEEE);
  static const Color glitch100 = Color(0xFFF2F2F2);
  static const Color glitch200 = Color(0xFFE2E2E2);
  static const Color glitch300 = Color(0xFFCDCECD);
  static const Color glitch400 = Color(0xFFAFB1AF);
  static const Color colorDC2626 = Color(0xFFDC2626);
  static const Color glitch500 = Color(0xFF8C908C);
  static const Color glitch600 = Color(0xFF727772);
  static const Color glitch700 = Color(0xFF5A605A);
  static const Color glitch800 = Color(0xFF474C47);
  static const Color glitch900 = Color(0xFF2D312D);
  static const Color glitch950 = Color(0xFF202320);

  static const ColorScheme glitchLightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: glitch950,
    onPrimary: glitch50,
    primaryContainer: glitch900,
    onPrimaryContainer: glitch50,
    secondary: glitch100,
    onSecondary: glitch900,
    secondaryContainer: glitch200,
    onSecondaryContainer: glitch900,
    tertiary: glitch400,
    onTertiary: glitch950,
    tertiaryContainer: glitch200,
    onTertiaryContainer: glitch950,
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFF1F2),
    errorContainer: Color(0xFFFFE5E5),
    onErrorContainer: Color(0xFF690005),
    surface: glitch50,
    onSurface: glitch950,
    onSurfaceVariant: glitch900,
    outline: glitch300,
    outlineVariant: glitch200,
    shadow: Colors.black,
    scrim: Colors.black54,
    inverseSurface: glitch900,
    onInverseSurface: glitch50,
    inversePrimary: glitch100,
    surfaceTint: glitch950,
    surfaceContainerHighest: glitch100,
    surfaceContainerHigh: glitch100,
    surfaceContainer: glitch100,
    surfaceContainerLow: glitch50,
    surfaceContainerLowest: glitch50,
  );

  static const ColorScheme glitchDarkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: glitch50,
    onPrimary: glitch950,
    primaryContainer: glitch200,
    onPrimaryContainer: glitch950,
    secondary: glitch800,
    onSecondary: glitch50,
    secondaryContainer: glitch700,
    onSecondaryContainer: glitch50,
    tertiary: glitch400,
    onTertiary: glitch50,
    tertiaryContainer: glitch700,
    onTertiaryContainer: glitch50,
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFF1F2),
    errorContainer: Color(0xFF37000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: glitch950,
    onSurface: glitch50,
    onSurfaceVariant: glitch50,
    outline: glitch600,
    outlineVariant: glitch800,
    shadow: Colors.black,
    scrim: Colors.black54,
    inverseSurface: glitch50,
    onInverseSurface: glitch900,
    inversePrimary: glitch900,
    surfaceTint: glitch50,
    surfaceContainerHighest: glitch800,
    surfaceContainerHigh: glitch800,
    surfaceContainer: glitch800,
    surfaceContainerLow: glitch950,
    surfaceContainerLowest: glitch950,
  );
}
