import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/config/providers/relay_status_provider.dart';
import 'package:whitenoise/models/relay_status.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/settings/network/widgets/network_section.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  final logger = Logger('NetworkScreen');
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
    } catch (e, stackTrace) {
      logger.severe('NetworkScreen: Error refreshing relay data: $e');
      logger.severe('NetworkScreen: Stack trace: $stackTrace');
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
                              onTap: () {},
                              child: Icon(
                                CarbonIcons.help,
                                color: context.colors.mutedForeground,
                                size: 18.sp,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () {},
                              child: Icon(
                                CarbonIcons.rotate,
                                color: context.colors.primary,
                                size: 20.sp,
                              ),
                            ),
                            Gap(16.w),
                            InkWell(
                              onTap: () {},
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
                          child: ListView.separated(
                            itemBuilder:
                                (context, index) => RelayTile(
                                  relayInfo: allRelays[index],
                                ),
                            separatorBuilder: (context, index) => Gap(12.h),
                            padding: EdgeInsets.zero,
                            itemCount: allRelays.length,
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
    );
  }
}

class RelayTile extends StatelessWidget {
  const RelayTile({
    super.key,
    required this.relayInfo,
  });
  final RelayInfo relayInfo;
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
        leading: Icon(
          relayInfo.status.getIcon(),
          color: relayInfo.status.getColor(context),
        ),
        title: Text(
          relayInfo.url.sanitizedUrl,
          style: TextStyle(
            color: context.colors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 12.sp,
          ),
        ),
        trailing: InkWell(
          onTap: () {},
          child: Icon(
            CarbonIcons.overflow_menu_horizontal,
            color: context.colors.primary,
            size: 23.sp,
          ),
        ),
      ),
    );
  }
}
