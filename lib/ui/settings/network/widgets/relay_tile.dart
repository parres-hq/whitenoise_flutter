import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/models/relay_status.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/settings/network/widgets/network_section.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class RelayTile extends ConsumerStatefulWidget {
  const RelayTile({
    super.key,
    required this.relayInfo,
    this.showOptions = false,
    this.onDelete,
  });

  final RelayInfo relayInfo;
  final bool showOptions;
  final VoidCallback? onDelete;

  @override
  ConsumerState<RelayTile> createState() => _RelayTileState();
}

class _RelayTileState extends ConsumerState<RelayTile> {
  Future<void> _removeRelay() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => WnDialog.custom(
            customChild: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remove Relay?',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                    ),

                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: WnImage(
                        AssetsPaths.icClose,
                        color: context.colors.primary,

                        size: 24.w,
                      ),
                    ),
                  ],
                ),
                Gap(6.h),
                Text(
                  'Are you sure you want to remove this relay? To use it again, you’ll need to add it back manually.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.mutedForeground,
                  ),
                ),
                Gap(12.h),
                WnFilledButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  visualState: WnButtonVisualState.secondary,
                  label: 'Cancel',
                  size: WnButtonSize.small,
                ),
                Gap(8.h),
                WnFilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  visualState: WnButtonVisualState.destructive,
                  label: 'Remove Relay',
                  size: WnButtonSize.small,
                ),
              ],
            ),
          ),
    );

    if (confirmed == true && mounted) {
      if (widget.onDelete != null) {
        widget.onDelete!();
        ref.showSuccessToast('Relay removed successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 4.h,
        ),
        leading: WnImage(
          widget.relayInfo.status.getIconAsset(),
          color: widget.relayInfo.status.getColor(context),

          size: 24.w,
        ),
        title: Text(
          widget.relayInfo.url.sanitizedUrl,
          style: TextStyle(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
        trailing: InkWell(
          onTap: _removeRelay,
          child: WnImage(
            AssetsPaths.icDelete,
            color: context.colors.primary,

            size: 23.w,
          ),
        ),
      ),
    );
  }
}
