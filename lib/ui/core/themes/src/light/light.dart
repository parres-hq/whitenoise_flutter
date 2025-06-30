import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/colors.dart';
import 'package:whitenoise/ui/core/themes/src/constants.dart';
import 'package:whitenoise/ui/core/themes/src/dimensions.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/themes/src/typography/typography.dart';

part 'input.dart';

final lightColorScheme = const ColorScheme.light(
  primary: LightAppColors.primary,
  secondary: LightAppColors.secondary,
  tertiary: LightAppColors.tertiary,
  error: LightAppColors.destructive,
  // ignore: avoid_redundant_argument_values
  surface: LightAppColors.neutral,
  surfaceTint: Colors.transparent,
);

final lightTheme = ThemeData(
  extensions: [AppColorsThemeExt.light],
  fontFamily: manropeFontFamily,
  //
  scaffoldBackgroundColor: LightAppColors.neutral,
  textTheme: lightTextTheme,
  colorScheme: lightColorScheme,
  appBarTheme: buildAppBarTheme(),
  popupMenuTheme: buildPopupTheme(),
  listTileTheme: buildListTileTheme(),
  textButtonTheme: buildTextButtonTheme(),
  bottomSheetTheme: buildBottomSheetTheme(),
  elevatedButtonTheme: buildElevatedButtonTheme(),
  outlinedButtonTheme: buildOutlinedButtonTheme(),
  navigationBarTheme: buildBottomNavigationTheme(),
  segmentedButtonTheme: buildSegmentedButtonTheme(),
  inputDecorationTheme: buildInputDecorationThemeData(),
  scrollbarTheme: buildScrollBarTheme(),
  dividerTheme: buildDividerTheme(),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: LightAppColors.neutral,
    circularTrackColor: LightAppColors.neutral.withValues(alpha: .5),
  ),
);

DividerThemeData buildDividerTheme() {
  return DividerThemeData(
    color: LightAppColors.baseMuted,
    thickness: .6.sp,
    space: .6.sp,
  );
}

ScrollbarThemeData buildScrollBarTheme() {
  return ScrollbarThemeData(
    crossAxisMargin: 4,
    radius: const Radius.circular(5),
    thickness: const WidgetStatePropertyAll(5),
    thumbColor: WidgetStateProperty.resolveWith((state) {
      if (state.contains(WidgetState.dragged)) {
        return LightAppColors.tertiary;
      }
      return LightAppColors.tertiary.withValues(alpha: 0.5);
    }),
  );
}

BottomSheetThemeData buildBottomSheetTheme() {
  return const BottomSheetThemeData(
    backgroundColor: LightAppColors.neutral,
    shape: RoundedRectangleBorder(),
    showDragHandle: true,
    dragHandleColor: LightAppColors.baseMuted,
    dragHandleSize: Size(50, 3),
  );
}

ListTileThemeData buildListTileTheme() {
  return ListTileThemeData(
    titleTextStyle: lightTextTheme.labelLarge,
    subtitleTextStyle: lightTextTheme.bodySmall,
    iconColor: LightAppColors.primary,
  );
}

NavigationBarThemeData buildBottomNavigationTheme() {
  return NavigationBarThemeData(
    elevation: 1,
    shadowColor: Colors.black.withValues(alpha: .14),
    backgroundColor: LightAppColors.neutral,
    indicatorColor: LightAppColors.tertiary,
    iconTheme: WidgetStateProperty.resolveWith((state) {
      if (state.contains(WidgetState.selected)) {
        return const IconThemeData(color: LightAppColors.primary);
      }
      return const IconThemeData(color: LightAppColors.mutedForeground);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((state) {
      if (state.contains(WidgetState.selected)) {
        return lightTextTheme.bodySmall?.copyWith(color: LightAppColors.primary).semiBold;
      }
      return lightTextTheme.bodySmall;
    }),
  );
}

PopupMenuThemeData buildPopupTheme() {
  return PopupMenuThemeData(
    color: LightAppColors.neutral,
    iconSize: 12,
    textStyle: lightTextTheme.bodyMedium,
    position: PopupMenuPosition.under,
  );
}

AppBarTheme buildAppBarTheme() {
  return AppBarTheme(
    backgroundColor: LightAppColors.appBarBackground,
    iconTheme: IconThemeData(
      color: LightAppColors.solidPrimary,
      size: 18.sp,
    ),
    titleTextStyle: lightTextTheme.labelLarge?.semiBold.copyWith(
      color: LightAppColors.mutedForeground,
    ),
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
}

ElevatedButtonThemeData buildElevatedButtonTheme() {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: kMinimumButtonSize,
      foregroundColor: LightAppColors.neutral,
      backgroundColor: LightAppColors.primary,
    ),
  );
}

OutlinedButtonThemeData buildOutlinedButtonTheme() {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: kMinimumButtonSize,
      foregroundColor: LightAppColors.primary,
      side: const BorderSide(color: LightAppColors.primary),
    ),
  );
}

TextButtonThemeData buildTextButtonTheme() {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: kMinimumButtonSize,
      foregroundColor: LightAppColors.primary,
    ),
  );
}

SegmentedButtonThemeData buildSegmentedButtonTheme() {
  return SegmentedButtonThemeData(
    selectedIcon: const SizedBox.shrink(),
    style: SegmentedButton.styleFrom(
      textStyle: lightTextTheme.labelMedium?.medium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp),
      ),
      side: const BorderSide(color: LightAppColors.baseMuted),
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((state) {
        if (state.contains(WidgetState.selected)) {
          return LightAppColors.primary;
        }
        return LightAppColors.mutedForeground;
      }),
    ),
  );
}
