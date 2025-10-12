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
import 'package:whitenoise/utils/localization_extensions.dart';
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
                      'network.removeRelayTitle'.tr(),
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
                  'network.removeRelayConfirmation'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: context.colors.mutedForeground,
                  ),
                ),
                Gap(12.h),
                WnFilledButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  visualState: WnButtonVisualState.secondary,
                  label: 'shared.cancel'.tr(),
                  size: WnButtonSize.small,
                ),
                Gap(8.h),
                WnFilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  visualState: WnButtonVisualState.destructive,
                  label: 'shared.remove'.tr(),
                  size: WnButtonSize.small,
                ),
              ],
            ),
          ),
    );

    if (confirmed == true && mounted) {
      if (widget.onDelete != null) {
        widget.onDelete!();
        ref.showSuccessToast('network.relayRemovedSuccessfully'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.colors.surface,

          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            RepaintBoundary(
              child: WnImage(
                widget.relayInfo.status.getIconAsset(),
                color: widget.relayInfo.status.getColor(context),
                size: 24.w,
              ),
            ),
            SizedBox(width: 12.w),

            Expanded(
              child: RepaintBoundary(
                child: Text(
                  widget.relayInfo.url.sanitizedUrl,
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(width: 8.w),

            if (widget.showOptions)
              RepaintBoundary(
                child: Semantics(
                  label: 'Delete relay',
                  button: true,
                  child: GestureDetector(
                    onTap: _removeRelay,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: WnImage(
                        AssetsPaths.icDelete,
                        color: context.colors.primary,
                        size: 20.w,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
