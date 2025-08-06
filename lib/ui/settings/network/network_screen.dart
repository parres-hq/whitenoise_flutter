import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/config/providers/relay_status_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_refreshing_indicator.dart';
import 'package:whitenoise/ui/core/ui/wn_tooltip.dart';
import 'package:whitenoise/ui/settings/network/widgets/relay_expansion_tile.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  final logger = Logger('NetworkScreen');
  final GlobalKey _myRelayHelpIconKey = GlobalKey();
  final GlobalKey _inboxRelayHelpIconKey = GlobalKey();
  final GlobalKey _keyPackageRelayHelpIconKey = GlobalKey();
  GlobalKey? _currentOpenTooltipKey;
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isPulling = false;
  double _pullDistance = 0.0;

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

  void _showHelpTooltip(GlobalKey key, String message) {
    // If the same tooltip is already open, close it
    if (_currentOpenTooltipKey == key) {
      WnTooltip.hide();
      setState(() {
        _currentOpenTooltipKey = null;
      });
      return;
    }

    // Close any existing tooltip and open the new one
    WnTooltip.hide();
    WnTooltip.show(
      context: context,
      targetKey: key,
      message: message,
      maxWidth: 300.w,
    );
    setState(() {
      _currentOpenTooltipKey = key;
    });
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
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isPulling = true;
            _pullDistance = 0.0;
          });
        },
        onPanUpdate: (details) {
          if (_isPulling) {
            setState(() {
              _pullDistance += details.delta.dy;
              _pullDistance = _pullDistance.clamp(0.0, 100.0);
            });
          }
        },
        onPanEnd: (details) {
          if (_isPulling) {
            if (_pullDistance >= 60.0) {
              _refreshData();
            }
            setState(() {
              _isPulling = false;
              _pullDistance = 0.0;
            });
          }
        },
        child: PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              WnTooltip.hide();
              _currentOpenTooltipKey = null;
            }
          },
          child: GestureDetector(
            onTap: () {
              WnTooltip.hide();
              setState(() {
                _currentOpenTooltipKey = null;
              });
            },
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
                      if (_isPulling || _isRefreshing)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height:
                              _isPulling
                                  ? _pullDistance.clamp(
                                    0.0,
                                    60.h,
                                  )
                                  : 50.h,
                          child: Opacity(
                            opacity: _isPulling ? (_pullDistance / 60.h).clamp(0.0, 1.0) : 1.0,
                            child: const WnRefreshingIndicator(
                              message: 'Reconnecting Relays...',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        )
                      else
                        Gap(16.h),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Column(
                            children: [
                              Expanded(
                                child: ListView(
                                  padding: EdgeInsets.zero,
                                  children: [
                                    RelayExpansionTile(
                                      title: 'My Relays',
                                      helpIconKey: _myRelayHelpIconKey,
                                      relayState: normalRelaysState,
                                      relayNotifier: ref.read(normalRelaysProvider.notifier),
                                      onInfoTap:
                                          () => _showHelpTooltip(
                                            _myRelayHelpIconKey,
                                            'Relays you have defined for use across all your Nostr applications.',
                                          ),
                                    ),
                                    Gap(16.h),
                                    RelayExpansionTile(
                                      title: 'Inbox Relays',
                                      helpIconKey: _inboxRelayHelpIconKey,
                                      relayState: inboxRelaysState,
                                      relayNotifier: ref.read(inboxRelaysProvider.notifier),
                                      onInfoTap:
                                          () => _showHelpTooltip(
                                            _inboxRelayHelpIconKey,
                                            'Relays used to receive invitations and start secure conversations with new contacts.',
                                          ),
                                    ),
                                    Gap(16.h),
                                    RelayExpansionTile(
                                      title: 'Key Package Relays',
                                      helpIconKey: _keyPackageRelayHelpIconKey,
                                      relayState: keyPackageRelaysState,
                                      relayNotifier: ref.read(keyPackageRelaysProvider.notifier),
                                      onInfoTap:
                                          () => _showHelpTooltip(
                                            _keyPackageRelayHelpIconKey,
                                            'Relays that store your secure key so others can invite you to encrypted conversations.',
                                          ),
                                    ),
                                  ],
                                ),
                              ),
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
