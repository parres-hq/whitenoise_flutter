part of 'wn_button.dart';

class WnFilledButton extends WnButton {
  WnFilledButton({
    super.key,
    super.size,
    super.visualState,
    this.loading = false,
    this.prefixIcon,
    this.suffixIcon,
    this.labelTextStyle,
    required String label,
    required super.onPressed,
  }) : super(
         ignorePointer: loading,
         child: Row(
           mainAxisSize: MainAxisSize.min,
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             if (prefixIcon != null) ...[
               prefixIcon,
               size == WnButtonSize.small ? Gap(8.w) : Gap(12.w),
             ],
             FittedBox(
               fit: BoxFit.scaleDown,
               child: Text(
                 label,
                 style: labelTextStyle ?? size.textStyle(),
               ),
             ),
             if (suffixIcon != null) ...[
               size == WnButtonSize.small ? Gap(8.w) : Gap(12.w),
               suffixIcon,
             ],
           ],
         ),
       );

  final bool loading;
  final SvgPicture? prefixIcon;
  final SvgPicture? suffixIcon;
  final TextStyle? labelTextStyle;

  @override
  Widget buildButton(BuildContext context) {
    final theme = Theme.of(context).elevatedButtonTheme;

    final loadingIndicator = const ButtonLoadingIndicator();

    final effectiveStyle = (style ?? FilledButton.styleFrom())
        .merge(
          FilledButton.styleFrom(
            fixedSize: Size(size.value.width.w, size.value.height.h),
            backgroundColor: visualState.backgroundColor(context),
            foregroundColor: visualState.foregroundColor(context),
            iconColor: visualState.foregroundColor(context),
            disabledBackgroundColor: visualState.disabledBackgroundColor(
              context,
            ),
            disabledForegroundColor: visualState.disabledForegroundColor(
              context,
            ),
            side: BorderSide(
              color: visualState.borderColor(context),
            ),
            shape: const RoundedRectangleBorder(),
            elevation: 0,
            textStyle: size.textStyle().copyWith(
              color: visualState.foregroundColor(context),
            ),
          ),
        )
        .merge(theme.style);

    return FilledButton(
      style: effectiveStyle,
      onPressed: onPressed,
      onLongPress: onLongPress,
      child: !loading ? child : loadingIndicator,
    );
  }
}
