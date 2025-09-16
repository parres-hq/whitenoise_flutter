import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';

class CreateGroupDialog extends StatelessWidget {
  final VoidCallback? onCreateGroup;
  final VoidCallback? onCancel;
  final ContactModel? contactToAdd;

  const CreateGroupDialog({
    super.key,
    this.onCreateGroup,
    this.onCancel,
    this.contactToAdd,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: AlertDialog(
        backgroundColor: context.colors.surface,
        shape: const RoundedRectangleBorder(),
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create a Group to Continue',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colors.primary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancel ?? () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        size: 16.w,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Gap(8.h),

                Text(
                  'You are not a member of any groups. Make a new group to add someone.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.mutedForeground,
                    fontSize: 14.sp,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.left,
                ),
                Gap(16.h),

                Column(
                  children: [
                    WnFilledButton(
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                      label: 'Cancel',
                      visualState: WnButtonVisualState.secondary,
                      size: WnButtonSize.small,
                      labelTextStyle: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Gap(12.h),
                    WnFilledButton(
                      onPressed: onCreateGroup,
                      label: 'New Group Chat',
                      size: WnButtonSize.small,
                      labelTextStyle: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onCreateGroup,
    VoidCallback? onCancel,
    ContactModel? contactToAdd,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => CreateGroupDialog(
            onCreateGroup: onCreateGroup,
            onCancel: onCancel,
            contactToAdd: contactToAdd,
          ),
    );
  }
}
