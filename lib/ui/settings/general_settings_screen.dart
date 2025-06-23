import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';
import 'package:whitenoise/ui/settings/profile/add_profile_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/profile/switch_profile_bottom_sheet.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  List<AccountData> _accounts = [];
  AccountData? _currentAccount;
  Map<String, MetadataData?> _accountMetadata = {}; // Cache for metadata
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      setState(() => _isLoading = true);

      final accounts = await fetchAccounts();
      final activeAccountPubkey = ref.read(activeAccountProvider);

      // Load metadata for all accounts
      final metadataMap = <String, MetadataData?>{};
      for (final account in accounts) {
        try {
          final publicKey = await publicKeyFromString(publicKeyString: account.pubkey);
          final metadata = await fetchMetadata(pubkey: publicKey);
          metadataMap[account.pubkey] = metadata;
        } catch (e) {
          metadataMap[account.pubkey] = null;
        }
      }

      AccountData? currentAccount;
      if (activeAccountPubkey != null) {
        try {
          currentAccount = accounts.firstWhere(
            (account) => account.pubkey == activeAccountPubkey,
          );
        } catch (e) {
          // Active account not found, use first account
          if (accounts.isNotEmpty) {
            currentAccount = accounts.first;
            await ref.read(activeAccountProvider.notifier).setActiveAccount(currentAccount.pubkey);
          }
        }
      } else if (accounts.isNotEmpty) {
        // No active account set, use first account
        currentAccount = accounts.first;
        await ref.read(activeAccountProvider.notifier).setActiveAccount(currentAccount.pubkey);
      }

      setState(() {
        _accounts = accounts;
        _currentAccount = currentAccount;
        _accountMetadata = metadataMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load accounts: $e')),
        );
      }
    }
  }

  Future<void> _switchAccount(AccountData account) async {
    try {
      await ref.read(activeAccountProvider.notifier).setActiveAccount(account.pubkey);
      setState(() => _currentAccount = account);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account switched successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to switch account: $e')),
        );
      }
    }
  }

  ContactModel _accountToContactModel(AccountData account) {
    final metadata = _accountMetadata[account.pubkey];

    // Use metadata if available, otherwise fallback to pubkey
    final name = metadata?.name ?? account.pubkey.substring(0, 8);
    final displayName =
        metadata?.displayName ?? metadata?.name ?? 'Account ${account.pubkey.substring(0, 8)}';
    final about = metadata?.about ?? '';
    final picture = metadata?.picture ?? '';
    final nip05 = metadata?.nip05;

    return ContactModel(
      publicKey: account.pubkey,
      name: name,
      displayName: displayName,
      about: about,
      imagePath: picture,
      nip05: nip05,
    );
  }

  void _showAccountSwitcher() {
    final contactModels = _accounts.map(_accountToContactModel).toList();

    SwitchProfileBottomSheet.show(
      context: context,
      profiles: contactModels,
      onProfileSelected: (selectedProfile) {
        // Find the corresponding AccountData
        final selectedAccount = _accounts.firstWhere(
          (account) => account.pubkey == selectedProfile.publicKey,
        );
        _switchAccount(selectedAccount);
      },
    );
  }

  Future<void> _handleLogout() async {
    final authNotifier = ref.read(authProvider.notifier);
    final authState = ref.read(authProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await authNotifier.logoutCurrentAccount();

    if (!mounted) return;
    Navigator.of(context).pop();

    if (authState.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(authState.error!)));
      return;
    }

    context.go(Routes.home);
  }

  void _deleteAllData() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All data deleted')));
  }

  void _publishKeyPackage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Key package event published')),
    );
  }

  void _deleteKeyPackages() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All key package events deleted')),
    );
  }

  void _testNotifications() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Test notification sent')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_currentAccount != null)
            ContactListTile(
              contact: _accountToContactModel(_currentAccount!),
              showExpansionArrow: _accounts.length > 1,
              onTap: () {
                if (_accounts.length > 1) {
                  _showAccountSwitcher();
                }
              },
            )
          else
            const Center(child: Text('No accounts found')),
          SettingsListTile(
            icon: CarbonIcons.add,
            text: 'Add Profile',
            onTap: () => AddProfileBottomSheet.show(context: context),
          ),
          SettingsListTile(
            icon: CarbonIcons.user,
            text: 'Edit Profile',
            onTap: () => context.push('${Routes.settings}/profile'),
          ),
          SettingsListTile(
            icon: CarbonIcons.password,
            text: 'Nostr keys',
            onTap: () => context.push('${Routes.settings}/keys'),
          ),
          SettingsListTile(
            icon: CarbonIcons.satellite,
            text: 'Network',
            onTap: () => context.push('${Routes.settings}/network'),
          ),
          SettingsListTile(
            icon: CarbonIcons.wallet,
            text: 'Wallet',
            onTap: () => context.push('${Routes.settings}/wallet'),
          ),
          SettingsListTile(
            icon: CarbonIcons.logout,
            text: 'Sign out',
            onTap: _handleLogout,
          ),
          SettingsListTile(
            icon: CarbonIcons.delete,
            text: 'Delete all data',
            onTap: _deleteAllData,
          ),
          SettingsListTile(
            icon: CarbonIcons.password,
            text: 'Publish a key package event',
            onTap: _publishKeyPackage,
          ),
          SettingsListTile(
            icon: CarbonIcons.delete,
            text: 'Delete all key package events',
            onTap: _deleteKeyPackages,
          ),
          SettingsListTile(
            icon: CarbonIcons.notification,
            text: 'Test Notifications',
            onTap: _testNotifications,
          ),
        ],
      ),
    );
  }
}

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, size: 24.w, color: context.colors.mutedForeground),
            Gap(12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 17.sp,
                  color: context.colors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
