import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class AddRelayBottomSheet extends StatefulWidget {
  final Function(String) onRelayAdded;
  final String title;

  const AddRelayBottomSheet({super.key, required this.onRelayAdded, required this.title});

  @override
  State<AddRelayBottomSheet> createState() => _AddRelayBottomSheetState();

  static Future<void> show({
    required BuildContext context,
    required Function(String) onRelayAdded,
    required String title,
  }) async {
    await CustomBottomSheet.show(
      context: context,
      title: title,
      blurBackground: true,
      heightFactor: 0.35,
      builder: (context) => AddRelayBottomSheet(onRelayAdded: onRelayAdded, title: title),
    );
  }
}

class _AddRelayBottomSheetState extends State<AddRelayBottomSheet> {
  final TextEditingController _relayUrlController = TextEditingController();
  bool _isUrlValid = false;

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

  void _addRelay() {
    if (_isUrlValid) {
      widget.onRelayAdded(_relayUrlController.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste your relay address',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.glitch900),
              ),
              Gap(8.h),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      textController: _relayUrlController,
                      hintText: 'wss://',
                      autofocus: true,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  Gap(8.w),
                  CustomIconButton(onTap: () {}, iconPath: AssetsPaths.icPaste),
                ],
              ),
              Gap(16.h),
              if (!_isUrlValid) ...[
                Text(
                  'Invalid format: must start with wss://',
                  style: TextStyle(fontSize: 14.sp, color: AppColors.colorDC2626),
                ),
              ],
              Gap(16.h),
            ],
          ),
        ),
        CustomFilledButton(
          onPressed: _isUrlValid ? _addRelay : null,
          title: 'Add Relay',
          buttonType: ButtonType.primary,
        ),
        Gap(24.h),
      ],
    );
  }
}
