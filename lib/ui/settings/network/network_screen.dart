import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/config/providers/relay_status_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_refreshing_indicator.dart';
import 'package:whitenoise/ui/core/ui/wn_tooltip.dart';
import 'package:whitenoise/ui/settings/network/widgets/relay_section.dart';

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
                    RepaintBoundary(
                      child: _NetworkHeader(
                        onBackPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    RepaintBoundary(
                      child: _RefreshIndicator(
                        isPulling: _isPulling,
                        isRefreshing: _isRefreshing,
                        pullDistance: _pullDistance,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          children: [
                            Expanded(
                              child: _OptimizedScrollView(
                                onPullToRefresh: _refreshData,
                                onPullStateChanged: (isPulling, distance) {
                                  if (_isPulling != isPulling ||
                                      (_pullDistance - distance).abs() > 5.0) {
                                    setState(() {
                                      _isPulling = isPulling;
                                      _pullDistance = distance;
                                    });
                                  }
                                },
                                children: [
                                  RepaintBoundary(
                                    child: RelaySection(
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
                                  ),
                                  SizedBox(height: 16.h),
                                  RepaintBoundary(
                                    child: RelaySection(
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
                                  ),
                                  SizedBox(height: 16.h),
                                  RepaintBoundary(
                                    child: RelaySection(
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
    );
  }
}

/// Optimized network header widget
class _NetworkHeader extends StatelessWidget {
  const _NetworkHeader({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Row(
        children: [
          RepaintBoundary(
            child: IconButton(
              onPressed: onBackPressed,
              icon: WnImage(
                AssetsPaths.icChevronLeft,
                width: 24.w,
                height: 24.w,
                color: context.colors.primary,
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
    );
  }
}

/// Optimized refresh indicator widget
class _RefreshIndicator extends StatelessWidget {
  const _RefreshIndicator({
    required this.isPulling,
    required this.isRefreshing,
    required this.pullDistance,
  });

  final bool isPulling;
  final bool isRefreshing;
  final double pullDistance;

  @override
  Widget build(BuildContext context) {
    if (!isPulling && !isRefreshing) {
      return SizedBox(height: 16.h);
    }

    return Container(
      margin: EdgeInsets.only(top: isPulling ? 32.h : 0.0),
      height: isPulling ? pullDistance.clamp(0.0, 60.h) : 50.h,
      child: Opacity(
        opacity: isPulling ? (pullDistance / 60.h).clamp(0.0, 1.0) : 1.0,
        child: const WnRefreshingIndicator(
          message: 'Reconnecting Relays...',
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Optimized scroll view with throttled pull-to-refresh
class _OptimizedScrollView extends StatefulWidget {
  const _OptimizedScrollView({
    required this.children,
    required this.onPullToRefresh,
    required this.onPullStateChanged,
  });

  final List<Widget> children;
  final VoidCallback onPullToRefresh;
  final void Function(bool isPulling, double distance) onPullStateChanged;

  @override
  State<_OptimizedScrollView> createState() => _OptimizedScrollViewState();
}

class _OptimizedScrollViewState extends State<_OptimizedScrollView> {
  bool _isPulling = false;
  double _pullDistance = 0.0;

  DateTime? _lastScrollUpdate;
  static const Duration _scrollThrottle = Duration(milliseconds: 16); // ~60fps

  bool _shouldUpdateScroll() {
    final now = DateTime.now();
    if (_lastScrollUpdate == null || now.difference(_lastScrollUpdate!) > _scrollThrottle) {
      _lastScrollUpdate = now;
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification) {
          if (notification.metrics.pixels < 0) {
            final overscroll = notification.metrics.pixels.abs();
            final newDistance = (overscroll * 0.5).clamp(0.0, 100.0);

            if (_shouldUpdateScroll() && (newDistance - _pullDistance).abs() > 2.0) {
              if (!_isPulling) {
                _isPulling = true;
                _pullDistance = 0.0;
              }
              _pullDistance = newDistance;
              widget.onPullStateChanged(_isPulling, _pullDistance);
            }
          }
        }

        if (notification is ScrollEndNotification) {
          if (_isPulling && _pullDistance >= 60.0) {
            widget.onPullToRefresh();
          }
          if (_isPulling) {
            _isPulling = false;
            _pullDistance = 0.0;
            widget.onPullStateChanged(_isPulling, _pullDistance);
          }
        }
        return false;
      },
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: widget.children,
      ),
    );
  }
}
