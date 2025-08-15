import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/settings/network/add_relay_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/network/widgets/relay_tile.dart';

class RelayExpansionTile extends ConsumerStatefulWidget {
  final String title;
  final RelayState relayState;
  final VoidCallback? onInfoTap;
  final Notifier<RelayState> relayNotifier;
  final GlobalKey helpIconKey;

  const RelayExpansionTile({
    super.key,
    required this.title,
    required this.relayState,
    this.onInfoTap,
    required this.relayNotifier,
    required this.helpIconKey,
  });

  @override
  ConsumerState<RelayExpansionTile> createState() => _RelayExpansionTileState();
}

class _RelayExpansionTileState extends ConsumerState<RelayExpansionTile> {
  Future<void> _showAddRelayBottomSheet() async {
    await AddRelayBottomSheet.show(
      context: context,
      onRelayAdded: _addRelay,
    );
  }

  Future<void> _addRelay(String url) async {
    try {
      // Call the appropriate notifier's addRelay method
      if (widget.relayNotifier is NormalRelaysNotifier) {
        return await (widget.relayNotifier as NormalRelaysNotifier).addRelay(url);
      }
      if (widget.relayNotifier is InboxRelaysNotifier) {
        return await (widget.relayNotifier as InboxRelaysNotifier).addRelay(url);
      }
      if (widget.relayNotifier is KeyPackageRelaysNotifier) {
        return await (widget.relayNotifier as KeyPackageRelaysNotifier).addRelay(url);
      }
    } catch (e) {
      ref.showErrorToast('Failed to add relay: $e');
    }
  }

  Future<void> _deleteRelay(String url) async {
    try {
      // Call the appropriate notifier's deleteRelay method
      if (widget.relayNotifier is NormalRelaysNotifier) {
        return await (widget.relayNotifier as NormalRelaysNotifier).deleteRelay(url);
      }
      if (widget.relayNotifier is InboxRelaysNotifier) {
        return await (widget.relayNotifier as InboxRelaysNotifier).deleteRelay(url);
      }
      if (widget.relayNotifier is KeyPackageRelaysNotifier) {
        return await (widget.relayNotifier as KeyPackageRelaysNotifier).deleteRelay(url);
      }
    } catch (e) {
      ref.showErrorToast('Failed to delete relay: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      showTrailingIcon: false,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Row(
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontWeight: FontWeight.w600,
              fontSize: 16.w,
            ),
          ),
          Gap(8.w),
          if (widget.onInfoTap != null)
            InkWell(
              key: widget.helpIconKey,
              onTap: widget.onInfoTap,
              child: SvgPicture.asset(
                AssetsPaths.icHelp,
                colorFilter: ColorFilter.mode(
                  context.colors.mutedForeground,
                  BlendMode.srcIn,
                ),
                width: 18.sp,
                height: 18.sp,
              ),
            ),
          const Spacer(),
          InkWell(
            onTap: _showAddRelayBottomSheet,
            child: SvgPicture.asset(
              AssetsPaths.icAdd,
              colorFilter: ColorFilter.mode(
                context.colors.primary,
                BlendMode.srcIn,
              ),
              width: 23.sp,
              height: 23.sp,
            ),
          ),
        ],
      ),

      children: [
        if (widget.relayState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (widget.relayState.error != null)
          const Center(child: Text('Error Loading Relays'))
        else
          Column(
            children:
                widget.relayState.relays
                    .map(
                      (relay) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: RelayTile(
                          relayInfo: relay,
                          showOptions: true,
                          onDelete: () => _deleteRelay(relay.url),
                        ),
                      ),
                    )
                    .toList(),
          ),
      ],
    );
  }
}
