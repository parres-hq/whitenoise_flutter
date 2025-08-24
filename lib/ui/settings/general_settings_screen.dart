import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/accounts_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
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
  List<Account> _accounts = [];
  Account? _activeAccount;
  Map<String, ContactModel> _accountContactModels = {}; // Cache for contact models
  ProviderSubscription<AsyncValue<ProfileState>>? _profileSubscription;
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
      final accountsNotifier = ref.read(accountsProvider.notifier);
      await accountsNotifier.loadAccounts();
      final accounts = await accountsNotifier.readAccounts();
      final activeAccount = await accountsNotifier.readActiveAccount();

      setState(() {
        _accounts = accounts;
        _activeAccount = activeAccount;
      });
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to load accounts: $e');
      }
    } finally {}
  }

  Future<void> _switchAccount(Account account) async {
    try {
      await ref.read(accountsProvider.notifier).setActiveAccountPubkey(account.pubkey);
      await ref.read(profileProvider.notifier).fetchProfileData();
      // TODO big plans: load accoutns metadata
      // await ref.read(contactsProvider.notifier).loadContacts(account.pubkey);
      await ref.read(groupsProvider.notifier).loadGroups();
      setState(() => _activeAccount = account);

      if (mounted) {
        ref.showSuccessToast('Account switched successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to switch account: $e');
      }
    }
  }

  void _showAccountSwitcher({bool isDismissible = true, bool showSuccessToast = false}) {
    SwitchProfileBottomSheet.show(
      context: context,
      profiles: [], //contactModels,
      isDismissible: isDismissible,
      showSuccessToast: showSuccessToast,
      onProfileSelected: (selectedProfile) async {
        // Find the corresponding Account
        // Note: selectedProfile.publicKey is in npub format (from metadata cache)
        // but account.pubkey is in hex format (from getAccounts)
        // So we need to convert npub back to hex for matching

        Account? selectedAccount;

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
                    label: 'Cancel',
                    visualState: WnButtonVisualState.secondary,
                    size: WnButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: WnFilledButton(
                    label: 'Sign out',
                    labelTextStyle: WnButtonSize.small.textStyle().copyWith(
                      color: context.colors.solidNeutralWhite,
                    ),
                    visualState: WnButtonVisualState.destructive,
                    size: WnButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
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
    final accounts = await getAccounts();
    debugPrint('accounts: ${accounts.map((a) => a.pubkey).toList()}');
    debugPrint('accounts length: ${accounts.length}');
    final hasMultipleAccounts = accounts.length > 2;
    debugPrint('hasMultipleAccounts: ${hasMultipleAccounts}');

    if (!mounted) return;

    await authNotifier.logoutActiveAccount();

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
          icon: SvgPicture.asset(
            AssetsPaths.icChevronLeft,
            width: 24.w,
            height: 24.w,
            colorFilter: ColorFilter.mode(
              context.colors.primarySolid,
              BlendMode.srcIn,
            ),
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
                    // if (_currentAccount != null)
                    // TODO big plans: add account profile tile.
                    // ContactListTile(
                    //   contact: _accountToContactModel(_currentAccount!),
                    //   trailingIcon: SvgPicture.asset(
                    //     AssetsPaths.icQrCode,
                    //     width: 20.w,
                    //     height: 20.w,
                    //     colorFilter: ColorFilter.mode(
                    //       context.colors.primary,
                    //       BlendMode.srcIn,
                    //     ),
                    //   ),
                    //   onTap: () => context.push('${Routes.settings}/share_profile'),
                    // )
                    const Center(child: Text('No accounts found')),
                    Gap(12.h),
                    WnFilledButton(
                      label: 'Switch Account',
                      size: WnButtonSize.small,
                      visualState: WnButtonVisualState.secondary,
                      onPressed: () => _showAccountSwitcher(),
                      suffixIcon: SvgPicture.asset(
                        AssetsPaths.icArrowsVertical,
                        colorFilter: ColorFilter.mode(
                          context.colors.primary,
                          BlendMode.srcIn,
                        ),
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
                      assetPath: AssetsPaths.icUser,
                      text: 'Edit Profile',
                      onTap: () => context.push('${Routes.settings}/profile'),
                    ),
                    SettingsListTile(
                      assetPath: AssetsPaths.icPassword,
                      text: 'Profile Keys',
                      onTap: () => context.push('${Routes.settings}/keys'),
                    ),
                    SettingsListTile(
                      assetPath: AssetsPaths.icDataVis3,
                      text: 'Network Relays',
                      onTap: () => context.push('${Routes.settings}/network'),
                    ),
                    SettingsListTile(
                      assetPath: AssetsPaths.icLogout,
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
                      assetPath: AssetsPaths.icSettings,
                      text: 'App Settings',
                      onTap: () => context.push('${Routes.settings}/app_settings'),
                    ),
                    SettingsListTile(
                      assetPath: AssetsPaths.icFavorite,
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
                      assetPath: AssetsPaths.icDevelopment,
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
    required this.assetPath,
    required this.text,
    required this.onTap,
    this.foregroundColor,
  });

  final String assetPath;
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
            SvgPicture.asset(
              assetPath,
              width: 24.w,
              height: 24.w,
              colorFilter: ColorFilter.mode(
                foregroundColor ?? context.colors.primary,
                BlendMode.srcIn,
              ),
            ),
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
