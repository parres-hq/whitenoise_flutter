import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/config/providers/relay_status_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_refreshing_indicator.dart';
import 'package:whitenoise/ui/core/ui/wn_status_legend_item.dart';
import 'package:whitenoise/ui/core/ui/wn_tooltip.dart';
import 'package:whitenoise/ui/settings/network/add_relay_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/network/widgets/network_section.dart';
import 'package:whitenoise/ui/settings/network/widgets/relay_tile.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  final logger = Logger('NetworkScreen');
  final GlobalKey _helpIconKey = GlobalKey();
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Refresh data every time the page is entered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(initialLoad: true);
    });
  }

  Future<void> _refreshData({bool initialLoad = false}) async {
    try {
      if (_isRefreshing || _isLoading) return;

      if (initialLoad) {
        setState(() {
          _isLoading = true;
        });
      } else {
        setState(() {
          _isRefreshing = true;
        });
      }
      logger.info('NetworkScreen: Starting to refresh relay data');

      // First refresh the relay status provider
      logger.info('NetworkScreen: Loading relay statuses');
      await ref.read(relayStatusProvider.notifier).loadRelayStatuses();

      // Then refresh all relay providers
      logger.info('NetworkScreen: Loading all relay providers');
      await Future.wait([
        ref.read(normalRelaysProvider.notifier).loadRelays(),
        ref.read(inboxRelaysProvider.notifier).loadRelays(),
        ref.read(keyPackageRelaysProvider.notifier).loadRelays(),
      ]);
      logger.info('NetworkScreen: Successfully refreshed all relay data');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e, stackTrace) {
      logger.severe('NetworkScreen: Error refreshing relay data: $e');
      logger.severe('NetworkScreen: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalRelaysState = ref.watch(normalRelaysProvider);
    final inboxRelaysState = ref.watch(inboxRelaysProvider);
    final keyPackageRelaysState = ref.watch(keyPackageRelaysProvider);

    final allRelays =
        <RelayInfo>{
          ...normalRelaysState.relays,
          ...inboxRelaysState.relays,
          ...keyPackageRelaysState.relays,
        }.toList();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.dy > 0 && details.globalPosition.dy > 200) {
            _refreshData();
          }
        },
        child: PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              WnTooltip.hide();
            }
          },
          child: GestureDetector(
            onTap: () => WnTooltip.hide(),
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
                      if (_isRefreshing)
                        const WnRefreshingIndicator(
                          message: 'Reconnecting Relays...',
                        )
                      else
                        Gap(16.h),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Set Relays',
                                    style: TextStyle(
                                      color: context.colors.mutedForeground,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16.w,
                                    ),
                                  ),
                                  Gap(8.w),
                                  InkWell(
                                    key: _helpIconKey,
                                    onTap:
                                        () => WnTooltip.show(
                                          context: context,
                                          targetKey: _helpIconKey,
                                          message:
                                              'These relays store your chat history, deliver your messages, receive new ones, and help others find or invite you to chats.',
                                          maxWidth: 300.w,
                                          footer: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              WnStatusLegendItem(
                                                color: context.colors.success,
                                                label: 'Connected',
                                              ),
                                              Gap(8.h),
                                              WnStatusLegendItem(
                                                color: context.colors.info,
                                                label: 'Connects when needed',
                                              ),
                                              Gap(8.h),
                                              WnStatusLegendItem(
                                                color: context.colors.warning,
                                                label: 'Connecting',
                                              ),
                                              Gap(8.h),
                                              WnStatusLegendItem(
                                                color: context.colors.destructive,
                                                label: 'Failed to connect',
                                              ),
                                            ],
                                          ),
                                        ),

                                    child: Icon(
                                      CarbonIcons.help,
                                      color: context.colors.mutedForeground,
                                      size: 18.sp,
                                    ),
                                  ),
                                  const Spacer(),
                                  InkWell(
                                    onTap: _refreshData,
                                    child: Icon(
                                      CarbonIcons.rotate,
                                      color: context.colors.primary,
                                      size: 20.sp,
                                    ),
                                  ),
                                  Gap(16.w),
                                  InkWell(
                                    onTap:
                                        () => AddRelayBottomSheet.show(
                                          context: context,
                                          onRelayAdded: (_) {},
                                        ),
                                    child: Icon(
                                      CarbonIcons.add,
                                      color: context.colors.primary,
                                      size: 23.sp,
                                    ),
                                  ),
                                ],
                              ),
                              Gap(16.h),
                              Expanded(
                                flex: 0,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemBuilder:
                                      (context, index) => RelayTile(
                                        relayInfo: allRelays[index],
                                        showOptions: true,
                                      ),
                                  separatorBuilder: (context, index) => Gap(12.h),
                                  padding: EdgeInsets.zero,
                                  itemCount: allRelays.length,
                                ),
                              ),
                              Gap(16.h),
                              WnFilledButton.icon(
                                onPressed: () => context.go(Routes.settingsNetworkMonitor),
                                icon: const Text('Relay Monitor'),
                                label: SvgPicture.asset(
                                  AssetsPaths.icMonitor,
                                  colorFilter: ColorFilter.mode(
                                    context.colors.primaryForeground,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
