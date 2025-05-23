import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/settings/network/add_relay_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/network/relay_info_dialog.dart';
import 'package:whitenoise/ui/settings/network/widgets/network_section.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  final List<RelayInfo> _relays = [
    RelayInfo(url: 'wss://purplepag.es', connected: true),
    RelayInfo(url: 'wss://nostr.wine', connected: true),
    RelayInfo(url: 'wss://localhost:8080', connected: false),
  ];

  final List<RelayInfo> _inboxRelays = [RelayInfo(url: 'wss://auth.nostr1.com', connected: true)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: 'Network'),
      body: ListView(
        children: [
          Gap(24.w),
          NetworkSection(
            title: 'Relays',
            items: _relays,
            emptyText: "You don't have any relays configured.",
            onAddPressed: () {
              AddRelayBottomSheet.show(
                context: context,
                title: 'Add Relay',
                onRelayAdded: (url) {
                  setState(() {
                    _relays.add(RelayInfo(url: url, connected: false));
                  });
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
          ),
          NetworkSection(
            title: 'Relay List',
            items: const [],
            emptyText: "You don't have any normal relays configured.",
            onAddPressed: () {
              AddRelayBottomSheet.show(
                context: context,
                title: 'Add Relay List',
                onRelayAdded: (url) {
                  // Logic to add to relay list would go here
                  // This is placeholder since we don't have a real implementation
                },
              );
            },
            onInfoPressed: () {
              RelayInfoDialog.show(
                context,
                'About Relay List',
                'Relay lists allow you to share a collection of relays with others or subscribe to someone else\'s relay list.',
              );
            },
          ),
          NetworkSection(
            title: 'Inbox Relay List',
            items: _inboxRelays,
            emptyText: "You don't have any inbox relays configured.",
            onAddPressed: () {
              AddRelayBottomSheet.show(
                context: context,
                title: 'Add Inbox Relay',
                onRelayAdded: (url) {
                  setState(() {
                    _inboxRelays.add(RelayInfo(url: url, connected: false));
                  });
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
          ),
          NetworkSection(
            title: 'Key Package Relay List',
            items: const [],
            emptyText: "You don't have any key package relays configured.",
            onAddPressed: () {
              AddRelayBottomSheet.show(context: context, title: 'Add Key Package Relay', onRelayAdded: (url) {});
            },
            onInfoPressed: () {
              RelayInfoDialog.show(
                context,
                'About Key Package Relay List',
                'Key package relays store your encryption key packages for secure communication. They help others establish encrypted channels with you.',
              );
            },
          ),
        ],
      ),
    );
  }
}
