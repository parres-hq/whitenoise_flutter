part of 'wn_button.dart';

class WnFilledButton extends WnButton {
  WnFilledButton({
    super.key,
    super.size,
    super.visualState,
    this.loading = false,
    required String title,
    required super.onPressed,
  }) : super(
         ignorePointer: loading,
         child: Text(
           title,
           style: size.textStyle(),
         ),
       );

  const WnFilledButton.child({
    super.key,
    super.size,
    super.visualState,
    this.loading = false,
    required super.child,
    required super.onPressed,
  }) : super(ignorePointer: loading);

  const WnFilledButton.icon({
    super.key,
    super.size,
    super.icon,
    super.visualState,
    super.iconAlignment,
    this.loading = false,
    required Widget label,
    required super.onPressed,
  }) : super(child: label, ignorePointer: loading);

  final bool loading;

  @override
  Widget buildButton(BuildContext context) {
    final theme = Theme.of(context).elevatedButtonTheme;

    const loadingIndicator = ButtonLoadingIndicator();

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
          ),
        )
        .merge(theme.style);

    if (icon != null) {
      return FilledButton.icon(
        icon: icon,
        onPressed: onPressed,
        style: effectiveStyle,
        onLongPress: onLongPress,
        iconAlignment: iconAlignment,
        label: !loading ? child : loadingIndicator,
      );
    }

    return FilledButton(
      style: effectiveStyle,
      onPressed: onPressed,
      onLongPress: onLongPress,
      child: !loading ? child : loadingIndicator,
    );
  }
}
