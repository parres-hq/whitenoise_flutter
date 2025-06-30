import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/relay_provider.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/settings/network/add_relay_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/network/relay_info_dialog.dart';
import 'package:whitenoise/ui/settings/network/widgets/network_section.dart';

class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalRelaysState = ref.watch(normalRelaysProvider);
    final inboxRelaysState = ref.watch(inboxRelaysProvider);
    final keyPackageRelaysState = ref.watch(keyPackageRelaysProvider);

    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: const CustomAppBar(title: Text('Network')),
      body: ListView(
        children: [
          Gap(24.w),
          NetworkSection(
            title: 'Connected Relays',
            items: normalRelaysState.relays,
            isLoading: normalRelaysState.isLoading,
            error: normalRelaysState.error,
            emptyText: "You don't have any relays configured.",
            onAddPressed: () {
              AddRelayBottomSheet.show(
                context: context,
                title: 'Add Relay',
                onRelayAdded: (url) {
                  ref.read(normalRelaysProvider.notifier).addRelay(url);
                },
              );
            },
            onInfoPressed: () {
              RelayInfoDialog.show(
                context,
                'About Relays',
                'Relays are servers that help the Nostr network transmit and store your encrypted messages. Connect to multiple relays for better reliability.',
              );
            },
            onRefresh: () {
              ref.read(normalRelaysProvider.notifier).loadRelays();
            },
          ),
          NetworkSection(
            title: 'Inbox Relay List',
            items: inboxRelaysState.relays,
            isLoading: inboxRelaysState.isLoading,
            error: inboxRelaysState.error,
            emptyText: "You don't have any inbox relays configured.",
            onAddPressed: () {
              AddRelayBottomSheet.show(
                context: context,
                title: 'Add Inbox Relay',
                onRelayAdded: (url) {
                  ref.read(inboxRelaysProvider.notifier).addRelay(url);
                },
              );
            },
            onInfoPressed: () {
              RelayInfoDialog.show(
                context,
                'About Inbox Relay List',
                'Inbox relays are used specifically for receiving messages addressed to you. These relays should be reliable and have high uptime.',
              );
            },
            onRefresh: () {
              ref.read(inboxRelaysProvider.notifier).loadRelays();
            },
          ),
          NetworkSection(
            title: 'Key Package Relay List',
            items: keyPackageRelaysState.relays,
            isLoading: keyPackageRelaysState.isLoading,
            error: keyPackageRelaysState.error,
            emptyText: "You don't have any key package relays configured.",
            onAddPressed: () {
              AddRelayBottomSheet.show(
                context: context,
                title: 'Add Key Package Relay',
                onRelayAdded: (url) {
                  ref.read(keyPackageRelaysProvider.notifier).addRelay(url);
                },
              );
            },
            onInfoPressed: () {
              RelayInfoDialog.show(
                context,
                'About Key Package Relay List',
                'Key package relays store your encryption key packages for secure communication. They help others establish encrypted channels with you.',
              );
            },
            onRefresh: () {
              ref.read(keyPackageRelaysProvider.notifier).loadRelays();
            },
          ),
        ],
      ),
    );
  }
}
