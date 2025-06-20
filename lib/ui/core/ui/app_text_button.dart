part of 'app_button.dart';

class AppTextButton extends AppButton {
  AppTextButton(
    String title, {
    super.key,
    super.size,
    super.style,
    super.visualState,
    this.loading = false,
    required super.onPressed,
  }) : super(
         ignorePointer: loading,
         child: Text(
           title,
           style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
         ),
       );

  const AppTextButton.child({
    super.key,
    super.size,
    super.style,
    super.visualState,
    this.loading = false,
    required super.child,
    required super.onPressed,
  }) : super(ignorePointer: loading);

  AppTextButton.span({
    List<InlineSpan> children = const [],
    super.key,
    super.size,
    super.style,
    super.visualState,
    TextStyle? textStyle,
    this.loading = false,
    required super.onPressed,
  }) : super(
         ignorePointer: loading,
         child: RichText(
           text: TextSpan(
             children: children,
             style:
                 textStyle ??
                 TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
           ),
         ),
       );

  const AppTextButton.icon({
    super.key,
    super.size,
    super.icon,
    super.style,
    super.visualState,
    super.onLongPress,
    super.iconAlignment,
    this.loading = false,
    required Widget label,
    required super.onPressed,
  }) : super(child: label, ignorePointer: loading);

  final bool loading;

  @override
  Widget buildButton(BuildContext context) {
    const loadingIndicator = ButtonLoadingIndicator();
    final theme = Theme.of(context).textButtonTheme;

    final effectiveStyle = (style ?? TextButton.styleFrom())
        .merge(
          TextButton.styleFrom(
            minimumSize: Size(size.value.width.w, size.value.height.h),
            iconColor: visualState.backgroundColor(context),
            foregroundColor: visualState.foregroundColor(context),
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: context.colors.secondaryForeground,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: const RoundedRectangleBorder(),
          ),
        )
        .merge(theme.style);

    if (icon != null) {
      return TextButton.icon(
        icon: icon,
        onPressed: onPressed,
        style: effectiveStyle,
        onLongPress: onLongPress,
        iconAlignment: iconAlignment,
        label: !loading ? child : loadingIndicator,
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: effectiveStyle,
      onLongPress: onLongPress,
      child: !loading ? child : loadingIndicator,
    );
  }
}
