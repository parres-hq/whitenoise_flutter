import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/colors.dart';
import 'package:whitenoise/ui/core/themes/src/constants.dart';
import 'package:whitenoise/ui/core/themes/src/dimensions.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/themes/src/typography/typography.dart';

part 'extensions.dart';
part 'input.dart';

final darkColorScheme = const ColorScheme.dark(
  primary: DarkAppColors.primary,
  secondary: DarkAppColors.secondary,
  tertiary: DarkAppColors.tertiary,
  error: DarkAppColors.destructive,
  surfaceTint: Colors.transparent,
  surface: DarkAppColors.neutral,
);

final darkTheme = ThemeData(
  extensions: [AppColorsThemeExt.dark],
  fontFamily: 'OverusedGrotesk',
  //
  scaffoldBackgroundColor: DarkAppColors.neutral,
  textTheme: darkTextTheme,
  colorScheme: darkColorScheme,
  appBarTheme: buildDarkAppBarTheme(),
  popupMenuTheme: buildDarkPopupTheme(),
  listTileTheme: buildDarkListTileTheme(),
  textButtonTheme: buildDarkTextButtonTheme(),
  bottomSheetTheme: buildDarkBottomSheetTheme(),
  elevatedButtonTheme: buildDarkElevatedButtonTheme(),
  outlinedButtonTheme: buildDarkOutlinedButtonTheme(),
  navigationBarTheme: buildDarkBottomNavigationTheme(),
  segmentedButtonTheme: buildDarkSegmentedButtonTheme(),
  inputDecorationTheme: buildDarkInputDecorationThemeData(),
  scrollbarTheme: buildDarkScrollBarTheme(),
  dividerTheme: buildDarkDividerTheme(),
  progressIndicatorTheme: ProgressIndicatorThemeData(
    color: DarkAppColors.neutral,
    circularTrackColor: DarkAppColors.neutral.withValues(alpha: .5),
  ),
);

DividerThemeData buildDarkDividerTheme() {
  return DividerThemeData(
    color: DarkAppColors.baseMuted,
    thickness: .6.sp,
    space: .6.sp,
  );
}

ScrollbarThemeData buildDarkScrollBarTheme() {
  return ScrollbarThemeData(
    crossAxisMargin: 4,
    radius: const Radius.circular(5),
    thickness: const WidgetStatePropertyAll(5),
    thumbColor: WidgetStateProperty.resolveWith((state) {
      if (state.contains(WidgetState.dragged)) {
        return DarkAppColors.tertiary;
      }
      return DarkAppColors.tertiary.withValues(alpha: 0.5);
    }),
  );
}

BottomSheetThemeData buildDarkBottomSheetTheme() {
  return const BottomSheetThemeData(
    backgroundColor: DarkAppColors.neutral,
    shape: RoundedRectangleBorder(),
    showDragHandle: true,
    dragHandleColor: DarkAppColors.baseMuted,
    dragHandleSize: Size(50, 3),
  );
}

ListTileThemeData buildDarkListTileTheme() {
  return ListTileThemeData(
    titleTextStyle: darkTextTheme.labelLarge?.copyWith(
      color: DarkAppColors.secondaryForeground,
    ),
    subtitleTextStyle: darkTextTheme.bodySmall?.copyWith(color: DarkAppColors.mutedForeground),
    iconColor: DarkAppColors.primary,
  );
}

NavigationBarThemeData buildDarkBottomNavigationTheme() {
  return NavigationBarThemeData(
    elevation: 1,
    shadowColor: Colors.black.withValues(alpha: .14),
    backgroundColor: DarkAppColors.neutral,
    indicatorColor: DarkAppColors.tertiary,
    iconTheme: WidgetStateProperty.resolveWith((state) {
      if (state.contains(WidgetState.selected)) {
        return const IconThemeData(color: DarkAppColors.primary);
      }
      return const IconThemeData(color: DarkAppColors.mutedForeground);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((state) {
      if (state.contains(WidgetState.selected)) {
        return darkTextTheme.bodySmall?.copyWith(color: DarkAppColors.primary).semiBold;
      }
      return darkTextTheme.bodySmall;
    }),
  );
}

PopupMenuThemeData buildDarkPopupTheme() {
  return PopupMenuThemeData(
    color: DarkAppColors.neutral,
    iconSize: 12,
    textStyle: darkTextTheme.bodyMedium?.copyWith(color: DarkAppColors.secondaryForeground),
    position: PopupMenuPosition.under,
  );
}

AppBarTheme buildDarkAppBarTheme() {
  return AppBarTheme(
    backgroundColor: DarkAppColors.appBarBackground,
    iconTheme: IconThemeData(
      color: DarkAppColors.solidPrimary,
      size: 18.sp,
    ),
    titleTextStyle: darkTextTheme.labelLarge?.semiBold.copyWith(
      color: DarkAppColors.mutedForeground,
    ),
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
}

ElevatedButtonThemeData buildDarkElevatedButtonTheme() {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: kMinimumButtonSize,
      foregroundColor: DarkAppColors.neutral,
      backgroundColor: DarkAppColors.primary,
    ),
  );
}

OutlinedButtonThemeData buildDarkOutlinedButtonTheme() {
  return OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: kMinimumButtonSize,
      foregroundColor: DarkAppColors.primary,
      side: const BorderSide(color: DarkAppColors.primary),
    ),
  );
}

TextButtonThemeData buildDarkTextButtonTheme() {
  return TextButtonThemeData(
    style: TextButton.styleFrom(
      minimumSize: kMinimumButtonSize,
      foregroundColor: DarkAppColors.primary,
    ),
  );
}

SegmentedButtonThemeData buildDarkSegmentedButtonTheme() {
  return SegmentedButtonThemeData(
    selectedIcon: const SizedBox.shrink(),
    style: SegmentedButton.styleFrom(
      textStyle: darkTextTheme.labelMedium?.medium,
      backgroundColor: DarkAppColors.neutral,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp),
      ),
      side: const BorderSide(color: DarkAppColors.baseMuted),
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((state) {
        if (state.contains(WidgetState.selected)) {
          return DarkAppColors.primary;
        }
        return DarkAppColors.mutedForeground;
      }),
    ),
  );
}
