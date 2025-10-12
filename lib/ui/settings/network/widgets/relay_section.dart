import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/settings/network/add_relay_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/network/widgets/relay_tile.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

/// Simplified relay section widget (no expansion/collapse functionality)
class RelaySection extends ConsumerStatefulWidget {
  final String title;
  final RelayState relayState;
  final VoidCallback? onInfoTap;
  final Notifier<RelayState> relayNotifier;
  final GlobalKey helpIconKey;

  const RelaySection({
    super.key,
    required this.title,
    required this.relayState,
    this.onInfoTap,
    required this.relayNotifier,
    required this.helpIconKey,
  });

  @override
  ConsumerState<RelaySection> createState() => _RelaySectionState();
}

class _RelaySectionState extends ConsumerState<RelaySection> {
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
      ref.showErrorToast('${'network.failedToAddRelay'.tr()}: $e');
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
      ref.showErrorToast('${'network.failedToDeleteRelay'.tr()}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RepaintBoundary(
          child: Row(
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: context.colors.mutedForeground,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(width: 8.w),
              if (widget.onInfoTap != null)
                RepaintBoundary(
                  child: GestureDetector(
                    key: widget.helpIconKey,
                    onTap: widget.onInfoTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: WnImage(
                        AssetsPaths.icHelp,
                        color: context.colors.mutedForeground,
                        size: 18.w,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              RepaintBoundary(
                child: GestureDetector(
                  onTap: _showAddRelayBottomSheet,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: WnImage(
                      AssetsPaths.icAdd,
                      color: context.colors.primary,
                      size: 23.w,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        RepaintBoundary(
          child: _buildRelayList(),
        ),
      ],
    );
  }

  Widget _buildRelayList() {
    if (widget.relayState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.relayState.error != null) {
      return Center(child: Text('ui.errorLoadingRelays'.tr()));
    }

    if (widget.relayState.relays.length > 5) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.relayState.relays.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final relay = widget.relayState.relays[index];
          return RelayTile(
            relayInfo: relay,
            showOptions: true,
            onDelete: () => _deleteRelay(relay.url),
          );
        },
      );
    }

    return Column(
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
    );
  }
}
