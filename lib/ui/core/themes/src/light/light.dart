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

final lightColorScheme = ColorScheme.light(
  primary: lightColorsExt.primary,
  secondary: lightColorsExt.secondary,
  tertiary: lightColorsExt.tertiary,
  error: lightColorsExt.destructive,
  surface: lightColorsExt.neutral,
  surfaceTint: Colors.transparent,
);

final lightTheme = ThemeData(
  extensions: const [lightColorsExt],
  fontFamily: 'OverusedGrotesk',
  //
  scaffoldBackgroundColor: lightColorsExt.neutral,
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
    color: lightColorsExt.baseMuted,
    thickness: .6.sp,
    space: .6.sp,
  );
}

ScrollbarThemeData buildScrollBarTheme() {
  return ScrollbarThemeData(
    crossAxisMargin: 4,
    radius: const Radius.circular(5),
    thickness: const WidgetStatePropertyAll(5),
    thumbColor: WidgetStateProperty.resolveWith(
      (state) {
        if (state.contains(WidgetState.dragged)) {
          return lightColorsExt.tertiary;
        }
        return lightColorsExt.tertiary.withValues(alpha: 0.5);
      },
    ),
  );
}

BottomSheetThemeData buildBottomSheetTheme() {
  return BottomSheetThemeData(
    showDragHandle: true,
    dragHandleColor: lightColorsExt.baseMuted,
    dragHandleSize: const Size(50, 3),
  );
}

ListTileThemeData buildListTileTheme() {
  return ListTileThemeData(
    titleTextStyle: lightTextTheme.labelLarge,
    subtitleTextStyle: lightTextTheme.bodySmall,
    iconColor: lightColorsExt.primary,
  );
}

NavigationBarThemeData buildBottomNavigationTheme() {
  return NavigationBarThemeData(
    elevation: 1,
    shadowColor: Colors.black.withValues(alpha: .14),
    backgroundColor: lightColorsExt.neutral,
    indicatorColor: lightColorsExt.tertiary,
    iconTheme: WidgetStateProperty.resolveWith(
      (state) {
        if (state.contains(WidgetState.selected)) {
          return IconThemeData(
            color: lightColorsExt.primary,
          );
        }
        return IconThemeData(
          color: lightColorsExt.mutedForeground,
        );
      },
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (state) {
        if (state.contains(WidgetState.selected)) {
          return lightTextTheme.bodySmall
              ?.copyWith(
                color: lightColorsExt.primary,
              )
              .semiBold;
        }
        return lightTextTheme.bodySmall;
      },
    ),
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
    backgroundColor: lightColorsExt.primary,
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
      side: BorderSide(
        color: lightColorsExt.baseMuted,
      ),
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith(
        (state) {
          if (state.contains(WidgetState.selected)) {
            return lightColorsExt.primary;
          }
          return lightColorsExt.mutedForeground;
        },
      ),
    ),
  );
}
