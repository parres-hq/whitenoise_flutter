part of 'light.dart';

InputDecorationTheme buildInputDecorationThemeData() {
  const borderSide = BorderSide(
    color: LightAppColors.baseMuted,
  );
  final border = OutlineInputBorder(
    borderRadius: AppDimension.zeroBorder,
    borderSide: borderSide,
  );

  return InputDecorationTheme(
    enabledBorder: border,

    hintStyle: lightTextTheme.bodySmall?.copyWith(
      color: lightColorsExt.mutedForeground,
    ),

    labelStyle: WidgetStateTextStyle.resolveWith((state) {
      const tTheme = TextStyle();

      if (state.contains(WidgetState.error)) {
        return tTheme.copyWith(
          color: lightColorsExt.destructive,
        );
      }

      if (state.contains(WidgetState.focused)) {
        return tTheme.copyWith(
          color: lightColorsExt.primary,
        );
      }

      if (state.contains(WidgetState.disabled)) {
        return tTheme.copyWith(
          color: lightColorsExt.mutedForeground.withValues(alpha: .38),
        );
      }

      return tTheme;
    }),

    //
    focusedBorder: border.copyWith(
      borderSide: borderSide.copyWith(
        color: lightColorsExt.primary,
      ),
    ),

    //
    errorBorder: border.copyWith(
      borderSide: borderSide.copyWith(
        color: lightColorsExt.destructive,
      ),
    ),

    //
    disabledBorder: border.copyWith(),
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),

    //
    focusedErrorBorder: border.copyWith(
      borderSide: borderSide.copyWith(
        color: lightColorsExt.destructive,
      ),
    ),

    border: border,

    //
    floatingLabelBehavior: FloatingLabelBehavior.never,
  );
}
