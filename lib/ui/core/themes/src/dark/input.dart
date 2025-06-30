part of 'dark.dart';

InputDecorationTheme buildDarkInputDecorationThemeData() {
  const borderSide = BorderSide(color: DarkAppColors.input);
  final border = OutlineInputBorder(
    borderRadius: AppDimension.zeroBorder,
    borderSide: borderSide,
  );

  return InputDecorationTheme(
    enabledBorder: border,
    hintStyle: lightTextTheme.bodySmall?.copyWith(
      color: DarkAppColors.mutedForeground.withValues(alpha: .5),
    ),

    //
    labelStyle: WidgetStateTextStyle.resolveWith((state) {
      const tTheme = TextStyle();

      if (state.contains(WidgetState.error)) {
        return tTheme.copyWith(color: DarkAppColors.destructive);
      }

      if (state.contains(WidgetState.focused)) {
        return tTheme.copyWith(color: DarkAppColors.primary);
      }

      if (state.contains(WidgetState.disabled)) {
        return tTheme.copyWith(
          color: DarkAppColors.mutedForeground.withValues(alpha: .38),
        );
      }

      return tTheme;
    }),

    //
    focusedBorder: border.copyWith(
      borderSide: borderSide.copyWith(color: DarkAppColors.primary),
    ),

    //
    errorBorder: border.copyWith(
      borderSide: borderSide.copyWith(color: DarkAppColors.destructive),
    ),

    //
    disabledBorder: border.copyWith(),
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),

    //
    focusedErrorBorder: border.copyWith(
      borderSide: borderSide.copyWith(color: DarkAppColors.destructive),
    ),

    border: border,

    //
    floatingLabelBehavior: FloatingLabelBehavior.never,
  );
}
