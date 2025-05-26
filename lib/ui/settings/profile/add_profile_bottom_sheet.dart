import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
import 'package:whitenoise/ui/core/ui/custom_textfield.dart';

class AddProfileBottomSheet extends StatefulWidget {
  final VoidCallback? onSignIn;
  
  const AddProfileBottomSheet({
    super.key,
    this.onSignIn,
  });

  static Future<void> show({
    required BuildContext context,
    VoidCallback? onSignIn,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Add new profile',
      heightFactor: 0.42,
      backgroundColor: Colors.white,
      builder: (context) => AddProfileBottomSheet(
        onSignIn: onSignIn,
      ),
    );
  }

  @override
  State<AddProfileBottomSheet> createState() => _AddProfileBottomSheetState();
}

class _AddProfileBottomSheetState extends State<AddProfileBottomSheet> {
  final TextEditingController _privateKeyController = TextEditingController();

  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Nostr private key will be only stored securely on this device.',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: AppColors.glitch600,
                ),
              ),
              Gap(24.h),
              Text(
                'Sign in with your Nostr private key',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.glitch950,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Gap(8.h),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: CustomTextField(
            textController: _privateKeyController,
            hintText: 'nsec1...',
            padding: EdgeInsets.zero,
            obscureText: true,
          ),
        ),
        Gap(40.h),
        CustomFilledButton(
          onPressed: () {
            if (_privateKeyController.text.isNotEmpty) {
              Navigator.pop(context);
              if (widget.onSignIn != null) {
                widget.onSignIn!();
              }
            }
          },
          title: 'Sign In',
        ),
      ],
    );
  }
}
