import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/config/providers/relay_status_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/whitenoise_dialog.dart';
import 'package:whitenoise/ui/settings/network/add_relay_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/network/widgets/network_section.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data every time the page is entered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    try {
      debugPrint('NetworkScreen: Starting to refresh relay data');

      // First refresh the relay status provider
      debugPrint('NetworkScreen: Loading relay statuses');
      await ref.read(relayStatusProvider.notifier).loadRelayStatuses();

      // Then refresh all relay providers
      debugPrint('NetworkScreen: Loading all relay providers');
      await Future.wait([
        ref.read(normalRelaysProvider.notifier).loadRelays(),
        ref.read(inboxRelaysProvider.notifier).loadRelays(),
        ref.read(keyPackageRelaysProvider.notifier).loadRelays(),
      ]);

      debugPrint('NetworkScreen: Successfully refreshed all relay data');
    } catch (e, stackTrace) {
      debugPrint('NetworkScreen: Error refreshing relay data: $e');
      debugPrint('NetworkScreen: Stack trace: $stackTrace');
    }
  }

  Future<void> _deleteRelay(
    BuildContext context,
    WidgetRef ref,
    RelayInfo relay,
    NotifierProvider<dynamic, RelayState> provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (dialogContext) => WhitenoiseDialog(
            title: 'Delete Relay?',
            content: 'Removing this relay will stop all connections to it.',
            actions: Row(
              children: [
                Expanded(
                  child: AppFilledButton(
                    title: 'Cancel',
                    visualState: AppButtonVisualState.secondary,
                    size: AppButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: AppFilledButton(
                    title: 'Remove',
                    visualState: AppButtonVisualState.error,
                    size: AppButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ),
    );

    if (confirmed == true) {
      try {
        await ref.read(provider.notifier).deleteRelay(relay.url);
        ref.showRawSuccessToast('Relay removed successfully');
      } catch (e) {
        ref.showRawErrorToast('Failed to remove relay');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalRelaysState = ref.watch(normalRelaysProvider);
    final inboxRelaysState = ref.watch(inboxRelaysProvider);
    final keyPackageRelaysState = ref.watch(keyPackageRelaysProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.appBarBackground,
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: context.colors.neutral,
            child: Column(
              children: [
                Gap(20.h),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: SvgPicture.asset(
                        AssetsPaths.icChevronLeft,
                        colorFilter: ColorFilter.mode(
                          context.colors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Text(
                      'Network Relays',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    children: [
                      _CollapsibleRelaySection(
                        title: 'Relays',
                        relays: normalRelaysState.relays,
                        isLoading: normalRelaysState.isLoading,
                        error: normalRelaysState.error,
                        onAddPressed: () {
                          AddRelayBottomSheet.show(
                            context: context,
                            title: 'Add Relay',
                            onRelayAdded: (url) {
                              ref.read(normalRelaysProvider.notifier).addRelay(url);
                            },
                          );
                        },
                        onDeleteRelay:
                            (relay) => _deleteRelay(context, ref, relay, normalRelaysProvider),
                      ),
                      Gap(16.h),
                      _CollapsibleRelaySection(
                        title: 'Inbox Relays',
                        relays: inboxRelaysState.relays,
                        isLoading: inboxRelaysState.isLoading,
                        error: inboxRelaysState.error,
                        onAddPressed: () {
                          AddRelayBottomSheet.show(
                            context: context,
                            title: 'Add Inbox Relay',
                            onRelayAdded: (url) {
                              ref.read(inboxRelaysProvider.notifier).addRelay(url);
                            },
                          );
                        },
                        onDeleteRelay:
                            (relay) => _deleteRelay(context, ref, relay, inboxRelaysProvider),
                      ),
                      Gap(16.h),
                      _CollapsibleRelaySection(
                        title: 'Key Package Relays',
                        relays: keyPackageRelaysState.relays,
                        isLoading: keyPackageRelaysState.isLoading,
                        error: keyPackageRelaysState.error,
                        onAddPressed: () {
                          AddRelayBottomSheet.show(
                            context: context,
                            title: 'Add Key Package Relay',
                            onRelayAdded: (url) {
                              ref.read(keyPackageRelaysProvider.notifier).addRelay(url);
                            },
                          );
                        },
                        onDeleteRelay:
                            (relay) => _deleteRelay(context, ref, relay, keyPackageRelaysProvider),
                      ),
                      Gap(MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollapsibleRelaySection extends StatefulWidget {
  final String title;
  final List<RelayInfo> relays;
  final bool isLoading;
  final String? error;
  final VoidCallback onAddPressed;
  final Function(RelayInfo) onDeleteRelay;

  const _CollapsibleRelaySection({
    required this.title,
    required this.relays,
    required this.isLoading,
    required this.error,
    required this.onAddPressed,
    required this.onDeleteRelay,
  });

  @override
  State<_CollapsibleRelaySection> createState() => _CollapsibleRelaySectionState();
}

class _CollapsibleRelaySectionState extends State<_CollapsibleRelaySection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(0.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onAddPressed,
                  icon: Icon(
                    Icons.add,
                    size: 24.w,
                    color: context.colors.primary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 24.w,
                    minHeight: 24.w,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          if (widget.isLoading)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.colors.mutedForeground,
                  ),
                ),
              ),
            )
          else if (widget.error != null)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                widget.error!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.destructive,
                ),
              ),
            )
          else if (widget.relays.isEmpty)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'No relays configured',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
            )
          else
            ...widget.relays.map(
              (relay) => _RelayItem(
                relay: relay,
                onDelete: () => widget.onDeleteRelay(relay),
              ),
            ),
        ],
      ],
    );
  }
}

class _RelayItem extends StatelessWidget {
  final RelayInfo relay;
  final VoidCallback onDelete;

  const _RelayItem({
    required this.relay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(0.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
              child: Row(
                children: [
                  Icon(
                    relay.connected ? CarbonIcons.checkmark_filled : CarbonIcons.error_filled,
                    size: 16.w,
                    color: relay.connected ? context.colors.success : context.colors.destructive,
                  ),
                  Gap(9.w),
                  Flexible(
                    child: Text(
                      relay.url,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              CarbonIcons.trash_can,
              size: 20.w,
              color: context.colors.destructive,
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: 44.w,
              minHeight: 44.w,
            ),
          ),
        ],
      ),
    );
  }
}
