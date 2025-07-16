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
  bool _isUrlValid = false;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _relayUrlController.addListener(_validateUrl);
  }

  @override
  void dispose() {
    _relayUrlController.dispose();
    super.dispose();
  }

  void _validateUrl() {
    final url = _relayUrlController.text.trim();
    setState(() {
      _isUrlValid = url.startsWith('wss://') && url.length > 6;
    });
  }

  Future<void> _addRelay() async {
    if (!_isUrlValid || _isAdding) return;

    setState(() {
      _isAdding = true;
    });

    try {
      widget.onRelayAdded(_relayUrlController.text.trim());
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
        setState(() {
          _relayUrlController.text = clipboardData!.text!;
        });
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
                hintText: 'wss://',
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
        if (!_isUrlValid && _relayUrlController.text.isNotEmpty) ...[
          Text(
            'Invalid format: must start with wss://',
            style: TextStyle(
              fontSize: 14.sp,
              color: context.colors.destructive,
            ),
          ),
          Gap(8.h),
        ],
        AppFilledButton(
          onPressed: _isUrlValid && !_isAdding ? _addRelay : null,
          loading: _isAdding,
          title: widget.title,
        ),
        Gap(16.h),
      ],
    );
  }
}
