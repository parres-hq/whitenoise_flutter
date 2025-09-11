import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/user_profile_data_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show Account, getAccounts;
import 'package:whitenoise/ui/contact_list/widgets/contact_list_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/settings/developer/developer_settings_screen.dart';
import 'package:whitenoise/ui/settings/profile/switch_profile_bottom_sheet.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  List<Account> _accounts = [];
  Account? _currentAccount;
  final Map<String, ContactModel> _accountContactModels = {}; // Cache for contact models
  ProviderSubscription<AsyncValue<ActiveAccountState>>? _activeAccountSubscription;
  PackageInfo? _packageInfo;

  // Loading states
  bool _isLoadingAccounts = false;
  String? _loadingError;
  bool _isLoadingInProgress = false; // Prevent multiple simultaneous loads

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromProviders();
      _loadPackageInfo();
      _activeAccountSubscription = ref.listenManual(
        activeAccountProvider,
        (previous, next) {
          // Reload when account data changes (including metadata updates)
          if (next is AsyncData && !_isLoadingInProgress) {
            final newAccount = next.value?.account;
            final newMetadata = next.value?.metadata;

            // Check if account changed OR metadata updated
            final accountChanged = newAccount?.pubkey != _currentAccount?.pubkey;
            final metadataChanged =
                previous is AsyncData<ActiveAccountState> && previous.value.metadata != newMetadata;

            if (accountChanged || metadataChanged) {
              _refreshAccountData();
            }
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _activeAccountSubscription?.close();
    super.dispose();
  }

  // Load from existing providers instead of making new bridge calls
  Future<void> _loadFromProviders() async {
    if (!mounted) return;

    // Get active account from provider (already loaded at app startup)
    final activeAccountState = ref.read(activeAccountProvider);
    final activeAccount = activeAccountState.value?.account;
    final activeMetadata = activeAccountState.value?.metadata;

    if (activeAccount != null) {
      setState(() {
        _currentAccount = activeAccount;
      });

      // If we have metadata, create ContactModel immediately
      if (activeMetadata != null) {
        try {
          final contactModel = ContactModel.fromMetadata(
            pubkey: activeAccount.pubkey,
            metadata: activeMetadata,
          );
          setState(() {
            _accountContactModels[activeAccount.pubkey] = contactModel;
          });
        } catch (e) {
          debugPrint('Failed to create ContactModel from metadata: $e');
        }
      }

      // Only load additional accounts if we need the full list for switching
      _loadAccountsLazilyIfNeeded();
    } else {
      // Fallback: If no account in provider, load from API
      _loadAccountsFromApi();
    }
  }

  // Lazy load full account list only when needed
  Future<void> _loadAccountsLazilyIfNeeded() async {
    if (_accounts.isEmpty) {
      try {
        final accounts = await getAccounts();
        if (mounted) {
          setState(() {
            _accounts = accounts;
          });

          // Load contact models for non-active accounts using userProfileDataProvider
          _loadContactModelsForOtherAccounts(accounts);
        }
      } catch (e) {
        // Silently handle - account switching might not work but current account will show
        debugPrint('Failed to load accounts list: $e');
      }
    }
  }

  // Load contact models for accounts that don't have metadata yet
  Future<void> _loadContactModelsForOtherAccounts(List<Account> accounts) async {
    final userProfileDataNotifier = ref.read(userProfileDataProvider.notifier);

    for (final account in accounts) {
      // Skip if we already have this account's contact model
      if (!_accountContactModels.containsKey(account.pubkey)) {
        // Load in background, don't wait for all
        userProfileDataNotifier
            .getUserProfileData(account.pubkey)
            .then((contactModel) {
              if (mounted) {
                setState(() {
                  _accountContactModels[account.pubkey] = contactModel;
                });
              }
            })
            .catchError((e) {
              debugPrint('Failed to load profile data for ${account.pubkey}: $e');
              // Will use fallback in _accountToContactModel
            });
      }
    }
  }

  // Fallback method - only used if providers don't have data
  Future<void> _loadAccountsFromApi() async {
    if (!mounted || _isLoadingInProgress) return;

    _isLoadingInProgress = true;

    setState(() {
      _isLoadingAccounts = true;
      _loadingError = null;
    });

    try {
      final accounts = await getAccounts();
      final activeAccountState = ref.read(activeAccountProvider);
      final activeAccount = activeAccountState.value?.account;

      if (mounted) {
        setState(() {
          _accounts = accounts;
          _currentAccount = activeAccount;
          _isLoadingAccounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString();
          _isLoadingAccounts = false;
        });
        ref.showErrorToast('Failed to load accounts: $e');
      }
    } finally {
      _isLoadingInProgress = false;
    }
  }

  // Refresh account data including contact models (for profile updates)
  void _refreshAccountData() async {
    if (!mounted || _isLoadingInProgress) return;

    final activeAccountState = ref.read(activeAccountProvider);
    final activeAccount = activeAccountState.value?.account;
    final activeMetadata = activeAccountState.value?.metadata;

    if (activeAccount != null) {
      // Update current account immediately
      setState(() {
        _currentAccount = activeAccount;
      });

      // If provider has fresh metadata, use it immediately
      if (activeMetadata != null) {
        try {
          final contactModel = ContactModel.fromMetadata(
            pubkey: activeAccount.pubkey,
            metadata: activeMetadata,
          );
          setState(() {
            _accountContactModels[activeAccount.pubkey] = contactModel;
          });
          return;
        } catch (e) {
          debugPrint('Failed to create ContactModel from fresh metadata: $e');
        }
      }

      // No additional fallback needed - use basic account info
    }
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
      });
    } catch (e) {
      // Silently handle error - version info is not critical
      debugPrint('Failed to load package info: $e');
    }
  }

  Future<void> _switchAccount(Account account) async {
    try {
      await ref.read(activePubkeyProvider.notifier).setActivePubkey(account.pubkey);
      await ref.read(followsProvider.notifier).loadFollows();
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

  ContactModel _accountToContactModel(Account account) {
    final contactModel = _accountContactModels[account.pubkey];

    // Use cached contact model if available, otherwise create fallback
    if (contactModel != null) {
      return contactModel;
    }

    // Fallback contact model
    return ContactModel(
      publicKey: account.pubkey,
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
        // Find the corresponding Account
        // Note: selectedProfile.publicKey is in npub format (from metadata cache)
        // but account.pubkey is in hex format (from getAccounts)
        // So we need to convert npub back to hex for matching

        Account? selectedAccount;

        try {
          // Try to convert npub to hex for matching
          String hexKey = selectedProfile.publicKey;
          if (selectedProfile.publicKey.isValidNpubPublicKey) {
            hexKey = PubkeyFormatter(pubkey: selectedProfile.publicKey).toHex() ?? '';
          }

          selectedAccount = _accounts.where((account) => account.pubkey == hexKey).firstOrNull;
        } catch (e) {
          final hexProfilePubKey = PubkeyFormatter(pubkey: selectedProfile.publicKey).toHex();
          selectedAccount =
              _accounts.where((account) {
                final hexAccountPubkey = PubkeyFormatter(pubkey: account.pubkey).toHex();
                return hexAccountPubkey == hexProfilePubKey;
              }).firstOrNull;
        }

        if (selectedAccount != null) {
          await _switchAccount(selectedAccount);
          // Don't close the sheet - stay on settings screen after account switch
        } else {
          // Just show error, don't reload to prevent flickering
          if (mounted) {
            try {
              ref.showErrorToast('Account not found. Please try switching account again.');
            } catch (e) {
              debugPrint('Toast error: $e');
            }
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

    // Use cached accounts instead of making another bridge call
    final hasMultipleAccounts = _accounts.length > 2;

    if (!mounted) return;

    // Clear all draft messages before logout
    await DraftMessageService.clearAllDrafts();

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
        await _loadFromProviders();

        if (mounted) {
          _showAccountSwitcher(isDismissible: false, showSuccessToast: true);
        }
      } else {
        ref.showSuccessToast('Account signed out. Switched to the other available account.');
        await _loadFromProviders();
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
          icon: WnImage(
            AssetsPaths.icChevronLeft,
            width: 24.w,
            height: 24.w,
            color: context.colors.solidPrimary,
          ),
        ),
        title: Row(
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.solidPrimary,
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
                    if (_isLoadingAccounts)
                      const Center(child: CircularProgressIndicator())
                    else if (_loadingError != null)
                      const Center(child: Text('Error loading account'))
                    else if (_currentAccount != null)
                      ContactListTile(
                        contact: _accountToContactModel(_currentAccount!),
                        trailingIcon: WnImage(
                          AssetsPaths.icQrCode,
                          size: 20.w,
                          color: context.colors.primary,
                        ),
                        onTap: () => context.push('${Routes.settings}/share_profile'),
                      )
                    else
                      const Center(child: Text('No accounts found')),
                    Gap(12.h),
                    WnFilledButton(
                      label: 'Switch Account',
                      size: WnButtonSize.small,
                      visualState: WnButtonVisualState.secondary,
                      onPressed: () => _showAccountSwitcher(),
                      suffixIcon: WnImage(
                        AssetsPaths.icArrowsVertical,

                        color: context.colors.primary,
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
          // Version information at the bottom
          Gap(32.h),
          if (_packageInfo != null)
            Center(
              child: Text(
                'Version ${_packageInfo!.version}+${_packageInfo!.buildNumber}',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: context.colors.mutedForeground,
                ),
              ),
            ),
          Gap(16.h),
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
            WnImage(
              assetPath,
              size: 24.w,
              color: foregroundColor ?? context.colors.primary,
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
