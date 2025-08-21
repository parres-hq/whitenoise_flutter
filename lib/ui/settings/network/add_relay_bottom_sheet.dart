import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/relay_validation.dart';

class AddRelayBottomSheet extends ConsumerStatefulWidget {
  final Function(String) onRelayAdded;

  const AddRelayBottomSheet({
    super.key,
    required this.onRelayAdded,
  });

  @override
  ConsumerState<AddRelayBottomSheet> createState() => _AddRelayBottomSheetState();

  static Future<void> show({
    required BuildContext context,
    required Function(String) onRelayAdded,
  }) async {
    await WnBottomSheet.show(
      context: context,
      title: 'Add Relay',

      builder:
          (context) => AddRelayBottomSheet(
            onRelayAdded: onRelayAdded,
          ),
    );
  }
}

class _AddRelayBottomSheetState extends ConsumerState<AddRelayBottomSheet> {
  final TextEditingController _relayUrlController = TextEditingController();
  bool _isValidatingUrl = false;
  bool _validUrl = false;
  String? _relayValidationError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _relayUrlController.text = 'wss://';
    _relayUrlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _relayUrlController.removeListener(_onUrlChanged);
    _relayUrlController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _validateRelayUrl();
    });
  }

  Future<void> _validateRelayUrl() async {
    if (_isValidatingUrl) return;

    try {
      final url = _relayUrlController.text.trim();

      // If URL is empty or just the prefix, don't validate
      if (RelayValidation.shouldSkipValidation(url)) {
        setState(() {
          _isValidatingUrl = false;
          _validUrl = false;
          _relayValidationError = null;
        });
        return;
      }

      setState(() {
        _isValidatingUrl = true;
        _validUrl = false;
        _relayValidationError = null;
      });

      final String? validationError = RelayValidation.validateRelayUrl(url);

      if (validationError == null) {
        setState(() {
          _validUrl = true;
          _relayValidationError = null;
          _isValidatingUrl = false;
        });
      } else {
        setState(() {
          _validUrl = false;
          _relayValidationError = validationError;
          _isValidatingUrl = false;
        });
      }
    } catch (e) {
      ref.showErrorToast('Failed validating relay URL');
      setState(() {
        _isValidatingUrl = false;
        _validUrl = false;
      });
    }
  }

  Future<void> _addRelays() async {
    final relayUrl = _relayUrlController.text.trim();
    if (relayUrl.isEmpty || !_validUrl) {
      ref.showErrorToast('Please enter a valid relay URL');
      return;
    }
    Navigator.of(context).pop();
    widget.onRelayAdded(relayUrl);
    ref.showSuccessToast('Relay added successfully');
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        final String pastedText = clipboardData!.text!.trim();

        // If pasted text already starts with wss:// or ws://, use it as is
        // Otherwise, append it to wss://
        if (pastedText.startsWith('wss://') || pastedText.startsWith('ws://')) {
          _relayUrlController.text = pastedText;
        } else {
          // Add wss:// prefix to the pasted text
          _relayUrlController.text = 'wss://$pastedText';
        }

        // Trigger immediate validation after paste
        _debounceTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 100), _validateRelayUrl);

        ref.showRawSuccessToast('Pasted from clipboard');
      } else {
        ref.showRawErrorToast('No text found in clipboard');
      }
    } catch (e) {
      ref.showRawErrorToast('Failed to paste from clipboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Relay Address',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
        ),
        Gap(8.h),
        Row(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  WnTextFormField(
                    controller: _relayUrlController,
                    hintText: 'wss://relay.example.com',
                  ),
                ],
              ),
            ),
            Gap(4.w),
            CustomIconButton(
              onTap: _pasteFromClipboard,
              iconPath: AssetsPaths.icPaste,
              size: 56.h,
              padding: 20.w,
            ),
          ],
        ),
        Gap(16.h),
        if (_relayValidationError != null) ...[
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.colors.destructive.withValues(alpha: 0.1),

              border: Border.all(color: context.colors.destructive),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    WnImage(
                      AssetsPaths.icWarningFilled,
                      size: 16.w,
                      color: 
                        context.colors.destructive,
                        
                      ),
                    
                    Gap(8.w),
                    Text(
                      'Relay Not Supported',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
                Gap(8.h),
                Text(
                  _relayValidationError!,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),
          Gap(12.h),
        ],
        WnFilledButton(
          onPressed: _validUrl ? _addRelays : null,
          loading: _isValidatingUrl,
          label: 'Add Relay',
        ),
      ],
    );
  }
}
