import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class AddRelayBottomSheet extends ConsumerStatefulWidget {
  final Function(String) onRelayAdded;
  final String title;

  const AddRelayBottomSheet({
    super.key,
    required this.onRelayAdded,
    required this.title,
  });

  @override
  ConsumerState<AddRelayBottomSheet> createState() => _AddRelayBottomSheetState();

  static Future<void> show({
    required BuildContext context,
    required Function(String) onRelayAdded,
    required String title,
  }) async {
    await CustomBottomSheet.show(
      context: context,
      title: title,
      keyboardAware: true,
      builder: (context) => AddRelayBottomSheet(onRelayAdded: onRelayAdded, title: title),
    );
  }
}

class _AddRelayBottomSheetState extends ConsumerState<AddRelayBottomSheet> {
  final TextEditingController _relayUrlController = TextEditingController();
  bool _isAdding = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _relayUrlController.text = 'wss://';
  }

  @override
  void dispose() {
    _relayUrlController.dispose();
    super.dispose();
  }

  bool _validateUrl(String url) {
    // Valid if it starts with wss:// or ws:// and has content after the connection protocol prefix
    return (url.startsWith('wss://') && url.length > 5) ||
        (url.startsWith('ws://') && url.length > 5);
  }

  Future<void> _addRelay() async {
    if (_isAdding) return;

    final url = _relayUrlController.text.trim();

    // Validate URL when button is pressed
    if (!_validateUrl(url)) {
      setState(() {
        _validationError = 'Invalid format: must start with wss:// or ws://';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    setState(() {
      _isAdding = true;
    });

    try {
      widget.onRelayAdded(url);
      ref.showRawSuccessToast('Relay added successfully');
      Navigator.pop(context);
    } catch (e) {
      ref.showRawErrorToast('Failed to add relay');
    } finally {
      setState(() {
        _isAdding = false;
      });
    }
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
          'Enter your relay address',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: context.colors.primaryForeground,
          ),
        ),
        Gap(8.h),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                textController: _relayUrlController,
                hintText: 'wss://relay.example.com',
                padding: EdgeInsets.zero,
              ),
            ),
            Gap(8.w),
            CustomIconButton(
              onTap: _pasteFromClipboard,
              iconPath: AssetsPaths.icPaste,
            ),
          ],
        ),
        Gap(16.h),
        if (_validationError != null) ...[
          Text(
            _validationError!,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.destructive,
            ),
          ),
          Gap(8.h),
        ],
        AppFilledButton(
          onPressed: !_isAdding ? _addRelay : null,
          loading: _isAdding,
          title: widget.title,
        ),
      ],
    );
  }
}
