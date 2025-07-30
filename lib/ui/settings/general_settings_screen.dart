import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/settings/developer/developer_settings_screen.dart';
import 'package:whitenoise/ui/settings/profile/switch_profile_bottom_sheet.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  List<AccountData> _accounts = [];
  AccountData? _currentAccount;
  Map<String, ContactModel> _accountContactModels = {}; // Cache for contact models
  ProviderSubscription<AsyncValue<ProfileState>>? _profileSubscription;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccounts();
      // Listen for profile updates
      _profileSubscription = ref.listenManual(
        profileProvider,
        (previous, next) {
          // When profile is updated successfully, refresh the accounts
          if (next is AsyncData) {
            _loadAccounts();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _profileSubscription?.close();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      setState(() => _isLoading = true);
      final accounts = await fetchAccounts();
      final activeAccountPubkey = ref.read(activeAccountProvider);

      // Load metadata for all accounts using metadata cache
      final metadataCache = ref.read(metadataCacheProvider.notifier);
      final contactModels = <String, ContactModel>{};
      for (final account in accounts) {
        try {
          // Use metadata cache instead of direct fetchMetadata
          final contactModel = await metadataCache.getContactModel(account.pubkey);
          contactModels[account.pubkey] = contactModel;
        } catch (e) {
          // Create fallback contact model
          contactModels[account.pubkey] = ContactModel(
            name: 'Unknown User',
            publicKey: account.pubkey,
          );
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
        _accountContactModels = contactModels;
      });
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to load accounts: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _switchAccount(AccountData account) async {
    try {
      await ref.read(activeAccountProvider.notifier).setActiveAccount(account.pubkey);
      await ref.read(profileProvider.notifier).fetchProfileData();
      await ref.read(contactsProvider.notifier).loadContacts(account.pubkey);
      await ref.read(groupsProvider.notifier).loadGroups();
      setState(() => _currentAccount = account);

      if (mounted) {
        ref.showSuccessToast('Account switched successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to switch account: $e');
      }
    }
  }

  ContactModel _accountToContactModel(AccountData account) {
    final contactModel = _accountContactModels[account.pubkey];

    // Use cached contact model if available, otherwise create fallback
    if (contactModel != null) {
      return contactModel;
    }

    // Fallback contact model
    return ContactModel(
      publicKey: account.pubkey,
      name: account.pubkey.substring(0, 8),
      displayName: 'Account ${account.pubkey.substring(0, 8)}',
    );
  }

  void _showAccountSwitcher({bool isDismissible = true, bool showSuccessToast = false}) {
    final contactModels = _accounts.map(_accountToContactModel).toList();

    SwitchProfileBottomSheet.show(
      context: context,
      profiles: contactModels,
      isDismissible: isDismissible,
      showSuccessToast: showSuccessToast,
      onProfileSelected: (selectedProfile) async {
        // Find the corresponding AccountData
        // Note: selectedProfile.publicKey is in npub format (from metadata cache)
        // but account.pubkey is in hex format (from fetchAccounts)
        // So we need to convert npub back to hex for matching

        AccountData? selectedAccount;

        try {
          // Try to convert npub to hex for matching
          String hexKey = selectedProfile.publicKey;
          if (selectedProfile.publicKey.isValidNpubPublicKey) {
            hexKey = await hexPubkeyFromNpub(npub: selectedProfile.publicKey);
          }

          selectedAccount = _accounts.where((account) => account.pubkey == hexKey).firstOrNull;
        } catch (e) {
          // If conversion fails, try direct matching as fallback
          selectedAccount =
              _accounts.where((account) => account.pubkey == selectedProfile.publicKey).firstOrNull;
        }

        if (selectedAccount != null) {
          await _switchAccount(selectedAccount);
          // Don't close the sheet - stay on settings screen after account switch
        } else {
          // Account not found, reload accounts and show error
          if (mounted) {
            try {
              ref.showErrorToast('Account not found. Refreshing account list...');
            } catch (e) {
              // Fallback if toast fails - just reload accounts silently
              debugPrint('Toast error: $e');
            }
            _loadAccounts();
            // Don't close the sheet - stay on settings screen
          }
        }
      },
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (dialogContext) => WnDialog(
            title: 'Sign out',
            content:
                'Are you sure? If you haven\'t saved your private key, you won\'t be able to log back in.',
            actions: Row(
              children: [
                Expanded(
                  child: WnFilledButton(
                    title: 'Cancel',
                    visualState: WnButtonVisualState.secondary,
                    size: WnButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: WnFilledButton.child(
                    visualState: WnButtonVisualState.destructive,
                    size: WnButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      'Sign out',
                      style: WnButtonSize.small.textStyle().copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    // If user didn't confirm, return early
    if (confirmed != true) return;

    if (!mounted) return;

    final authNotifier = ref.read(authProvider.notifier);

    // Check if there are multiple accounts before logout
    final accounts = await fetchAccounts();
    final hasMultipleAccounts = accounts.length > 2;

    if (!mounted) return;

    await authNotifier.logoutCurrentAccount();

    if (!mounted) return;

    // Check the final auth state after logout
    final finalAuthState = ref.read(authProvider);

    if (finalAuthState.error != null) {
      ref.showErrorToast(finalAuthState.error!);
      return;
    }

    if (finalAuthState.isAuthenticated) {
      if (hasMultipleAccounts) {
        await _loadAccounts();

        if (mounted) {
          _showAccountSwitcher(isDismissible: false, showSuccessToast: true);
        }
      } else {
        ref.showSuccessToast('Account signed out. Switched to the other available account.');
        await _loadAccounts();
      }
    } else {
      ref.showSuccessToast('Signed out successfully.');
      if (mounted) {
        context.go(Routes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral,
      appBar: WnAppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            CarbonIcons.chevron_left,
            size: 24.w,
            color: context.colors.primarySolid,
          ),
        ),
        title: Row(
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.primarySolid,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_currentAccount != null)
                      ContactListTile(
                        contact: _accountToContactModel(_currentAccount!),
                        showExpansionArrow: true,
                        onTap: () => _showAccountSwitcher(),
                      )
                    else
                      const Center(child: Text('No accounts found')),
                    Gap(12.h),
                    WnFilledButton.child(
                      size: WnButtonSize.small,
                      visualState: WnButtonVisualState.secondary,
                      onPressed: () => context.push('${Routes.settings}/share_profile'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Share Profile',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                          Gap(9.w),
                          Icon(
                            CarbonIcons.qr_code,
                            size: 16.w,
                            color: context.colors.primary,
                          ),
                        ],
                      ),
                    ),
                    Gap(16.h),
                  ],
                ),
              ),
              Divider(color: context.colors.baseMuted, height: 0.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    Gap(10.h),
                    SettingsListTile(
                      icon: CarbonIcons.user,
                      text: 'Edit Profile',
                      onTap: () => context.push('${Routes.settings}/profile'),
                    ),
                    SettingsListTile(
                      icon: CarbonIcons.password,
                      text: 'Profile Keys',
                      onTap: () => context.push('${Routes.settings}/keys'),
                    ),
                    SettingsListTile(
                      icon: CarbonIcons.data_vis_3,
                      text: 'Network Relays',
                      onTap: () => context.push('${Routes.settings}/network'),
                    ),
                    SettingsListTile(
                      icon: CarbonIcons.logout,
                      text: 'Sign out',
                      onTap: _handleLogout,
                    ),
                  ],
                ),
              ),
              Divider(color: context.colors.baseMuted, height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SettingsListTile(
                      icon: CarbonIcons.settings,
                      text: 'App Settings',
                      onTap: () => context.push('${Routes.settings}/app_settings'),
                    ),
                    SettingsListTile(
                      icon: CarbonIcons.favorite,
                      text: 'Donate to White Noise',
                      onTap: () => context.push(Routes.settingsDonate),
                    ),
                  ],
                ),
              ),
              Divider(color: context.colors.baseMuted, height: 24.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SettingsListTile(
                      icon: CarbonIcons.development,
                      text: 'Developer Settings',
                      onTap: () => DeveloperSettingsScreen.show(context),
                      foregroundColor: context.colors.mutedForeground,
                    ),
                  ],
                ),
              ),
            ],
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
    this.foregroundColor,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            Icon(icon, size: 24.w, color: foregroundColor ?? context.colors.primary),
            Gap(12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor ?? context.colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
