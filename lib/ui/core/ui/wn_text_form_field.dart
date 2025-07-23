import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_validation_notification.dart';

enum FieldType {
  standard,
  password,
}

class WnTextFormField extends StatefulWidget {
  const WnTextFormField({
    super.key,
    this.formKey,
    this.hintText,
    this.labelText,
    this.validator,
    this.decoration,
    this.controller,
    this.enabled = true,
    this.expands = false,
    this.readOnly = false,
    this.maxLength,
    this.maxLines = 1,
    this.minLines = 1,
    this.focusNode,
    this.initialValue,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.onTap,
    this.style,
    this.obscureText,
    this.obscuringCharacter = '●',
    this.autocorrect = true,
    this.type = FieldType.standard,
    this.textAlign = TextAlign.start,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.inputFormatters,
  });

  final Key? formKey;
  final String? hintText;
  final bool autocorrect;
  final String? labelText;
  final FieldType? type;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final String? initialValue;
  final TextCapitalization textCapitalization;
  final ValueChanged<String?>? onSaved;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextStyle? style;
  final bool? obscureText;
  final TextAlign textAlign;
  final String obscuringCharacter;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  final bool expands;
  final bool enabled;
  final bool readOnly;
  final AutovalidateMode autovalidateMode;
  final TextEditingController? controller;
  final FormFieldValidator<String?>? validator;
  final InputDecoration? decoration;

  @override
  State<WnTextFormField> createState() => _WnTextFormFieldState();
}

class _WnTextFormFieldState extends State<WnTextFormField> {
  final hasError = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    final value = widget.initialValue ?? widget.controller?.text;
    final valid = widget.validator?.call(value) == null;
    context.dispatchNotification(WnValidationNotification(hashCode, valid));
    isObscuringText = widget.obscureText ?? widget.type == FieldType.password;
  }

  bool isObscuringText = true;
  void toggleIsObscuringText() {
    setState(() {
      isObscuringText = !isObscuringText;
    });
  }

  Widget? get suffixIcon {
    final resolvedIcon = ValueListenableBuilder(
      valueListenable: hasError,
      builder: (context, hasError, _) {
        final errorIcon = !hasError ? const SizedBox() : const Icon(Icons.error);

        return switch (widget.type) {
          FieldType.password => errorIcon,
          FieldType.standard || null => errorIcon,
        };
      },
    );

    return widget.decoration?.suffixIcon ?? resolvedIcon;
  }

  String? validator(dynamic value) {
    final result = widget.validator?.call(value);
    hasError.value = result != null;
    context.dispatchNotification(
      WnValidationNotification(hashCode, !hasError.value),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle =
        widget.style ??
        TextStyle(
          color: context.colors.primary,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        );

    final decoration = (widget.decoration ?? const InputDecoration()).copyWith(
      suffixIcon: suffixIcon,
      labelText: widget.labelText,
      hintText: widget.hintText,
      hintStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: context.colors.mutedForeground,
      ),
      suffixIconColor: context.colors.primary,
      fillColor: context.colors.avatarSurface,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 12.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: context.colors.input,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: context.colors.input,
        ),
      ),
      filled: true,
    );

    return TextFormField(
      key: widget.formKey,
      validator: validator,
      enabled: widget.enabled,
      expands: widget.expands,
      readOnly: widget.readOnly,
      enableInteractiveSelection: !widget.readOnly,
      controller: widget.controller,
      decoration: decoration,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      focusNode: widget.focusNode,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      autovalidateMode: widget.autovalidateMode,
      onFieldSubmitted: widget.onFieldSubmitted,
      onEditingComplete: widget.onEditingComplete,
      textCapitalization: widget.textCapitalization,
      onSaved: widget.onSaved,
      autocorrect: widget.autocorrect,
      onTap: widget.onTap,
      style: textStyle,
      textAlign: widget.textAlign,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText ?? isObscuringText,
      obscuringCharacter: widget.obscuringCharacter,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
    );
  }
}
