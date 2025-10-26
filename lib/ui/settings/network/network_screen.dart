import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/config/providers/relay_status_provider.dart';
import 'package:whitenoise/ui/core/ui/wn_tooltip.dart';
import 'package:whitenoise/ui/core/widgets/wn_settings_screen_wrapper.dart';
import 'package:whitenoise/ui/settings/network/widgets/relay_section.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

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

  @override
  void initState() {
    super.initState();
    // Load data when the page is entered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      if (_isLoading) return;

      setState(() {
        _isLoading = true;
      });

      logger.info('NetworkScreen: Starting to load relay data');

      // First load the relay status provider
      logger.info('NetworkScreen: Loading relay statuses');
      await ref.read(relayStatusProvider.notifier).loadRelayStatuses();

      // Then load all relay providers
      logger.info('NetworkScreen: Loading all relay providers');
      await Future.wait([
        ref.read(normalRelaysProvider.notifier).loadRelays(),
        ref.read(inboxRelaysProvider.notifier).loadRelays(),
        ref.read(keyPackageRelaysProvider.notifier).loadRelays(),
      ]);

      logger.info('NetworkScreen: Successfully loaded all relay data');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      logger.severe('NetworkScreen: Error loading relay data: $e');
      logger.severe('NetworkScreen: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
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

    return PopScope(
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
        child: WnSettingsScreenWrapper(
          title: 'settings.networkRelays'.tr(),
          onBackPressed: () => Navigator.of(context).pop(),
          body: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 16.h, left: 16.w, right: 16.w),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            RepaintBoundary(
                              child: RelaySection(
                                title: 'network.myRelays'.tr(),
                                helpIconKey: _myRelayHelpIconKey,
                                relayState: normalRelaysState,
                                relayNotifier: ref.read(normalRelaysProvider.notifier),
                                onInfoTap:
                                    () => _showHelpTooltip(
                                      _myRelayHelpIconKey,
                                      'network.myRelaysHelp'.tr(),
                                    ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            RepaintBoundary(
                              child: RelaySection(
                                title: 'network.inboxRelays'.tr(),
                                helpIconKey: _inboxRelayHelpIconKey,
                                relayState: inboxRelaysState,
                                relayNotifier: ref.read(inboxRelaysProvider.notifier),
                                onInfoTap:
                                    () => _showHelpTooltip(
                                      _inboxRelayHelpIconKey,
                                      'network.inboxRelaysHelp'.tr(),
                                    ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            RepaintBoundary(
                              child: RelaySection(
                                title: 'network.keyPackageRelays'.tr(),
                                helpIconKey: _keyPackageRelayHelpIconKey,
                                relayState: keyPackageRelaysState,
                                relayNotifier: ref.read(keyPackageRelaysProvider.notifier),
                                onInfoTap:
                                    () => _showHelpTooltip(
                                      _keyPackageRelayHelpIconKey,
                                      'network.keyPackageRelaysHelp'.tr(),
                                    ),
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
    );
  }
}
