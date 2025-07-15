import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/custom_bottom_sheet.dart';

class RemoveNostrKeysBottomSheet extends StatelessWidget {
  final VoidCallback onRemove;

  const RemoveNostrKeysBottomSheet({super.key, required this.onRemove});

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onRemove,
  }) {
    return CustomBottomSheet.show(
      context: context,
      title: 'Remove Nostr Keys',
      builder: (context) => RemoveNostrKeysBottomSheet(onRemove: onRemove),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 0.h, 24.w, 24.h),
          child: Text(
            'This will permanently erase this profile Nostr keys from White Noise.',
            style: TextStyle(
              fontSize: 16.sp,
              color: context.colors.mutedForeground,
            ),
          ),
        ),
        AppFilledButton(
          onPressed: Navigator.of(context).pop,
          title: 'Cancel',
        ),
        AppFilledButton(
          onPressed: onRemove,
          title: 'Remove Permanently',
          visualState: AppButtonVisualState.tertiary,
        ),
      ],
    );
  }
}
