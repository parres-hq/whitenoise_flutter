import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_validation_notification.dart';

enum FieldType {
  standard,
  password,
}

enum FieldSize {
  regular, // 56.h
  small, // 44.h
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
    this.size = FieldSize.regular,
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
  final FieldSize size;

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

  Widget? get suffixIcon =>
      hasError.value ? const Icon(Icons.error) : widget.decoration?.suffixIcon;

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

    final isSmall = widget.size == FieldSize.small;
    final targetHeight = isSmall ? 44.h : 56.h;

    final decoration = (widget.decoration ?? const InputDecoration()).copyWith(
      constraints:
          widget.maxLines != null || widget.minLines != null
              ? null
              : BoxConstraints.tightFor(height: targetHeight),
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
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: isSmall ? 13.5.h : 19.5.h),
      prefixIconConstraints: BoxConstraints.tightFor(height: targetHeight),
      suffixIconConstraints: BoxConstraints.tightFor(height: targetHeight),
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

    final field = TextFormField(
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

    // If maxLines or minLines is specified, return the field as is
    // Without using ConstainedBox to enforce the target height.
    // Same rule applied in InputDecoration above.
    if (widget.maxLines != null || widget.minLines != null) {
      return field;
    }
    // Also enforce the target height at the parent layout level so surrounding
    // widgets measure consistently. The decoration.constraints above ensures
    // the border matches this height (no extra whitespace around it).
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: targetHeight),
      child: field,
    );
  }
}
