import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

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
    return WnDialog.custom(
      customChild: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ui.createGroupToContinue'.tr(),
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.primary,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onCancel ?? () => Navigator.of(context).pop(),
                child: WnImage(
                  AssetsPaths.icClose,
                  size: 16.w,
                  color: context.colors.mutedForeground,
                ),
              ),
            ],
          ),
          Gap(8.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ui.noGroupsCreateDescription'.tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.mutedForeground,
                fontSize: 14.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Gap(16.h),
          Column(
            children: [
              WnFilledButton(
                onPressed: onCancel ?? () => Navigator.of(context).pop(),
                label: 'shared.cancel'.tr(),
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
                label: 'ui.newGroupChat'.tr(),
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
