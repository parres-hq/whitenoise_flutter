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
import 'package:whitenoise/config/providers/user_profile_data_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show Account, getAccounts;
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/settings/developer/developer_settings_screen.dart';
import 'package:whitenoise/ui/settings/profile/switch_profile_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/widgets/active_account_tile.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  List<Account> _accounts = [];
  List<ContactModel> _accountsProfileData = [];
  ProviderSubscription<AsyncValue<ActiveAccountState>>? _activeAccountSubscription;
  PackageInfo? _packageInfo;

  bool _isLoadingAccounts = false;
  bool _isLoadingPackageInfo = false;
  DateTime? _lastAccountsLoadTime;

  static const Duration _accountsCacheDuration = Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAccountsProfileData();
      _loadPackageInfo();
      _activeAccountSubscription = ref.listenManual(
        activeAccountProvider,
        (previous, next) {
          if (next is AsyncData) {
            // This ensures profile updates are reflected immediately
            _invalidateAccountsCache();
            _loadAccountsProfileData();
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

  Future<void> _loadAccountsProfileDataIfNeeded() async {
    if (_lastAccountsLoadTime != null) {
      final cacheAge = DateTime.now().difference(_lastAccountsLoadTime!);
      if (cacheAge < _accountsCacheDuration &&
          _accounts.isNotEmpty &&
          _accountsProfileData.isNotEmpty) {
        return; // Use cached data
      }
    }
    await _loadAccountsProfileData();
  }

  void _invalidateAccountsCache() {
    _lastAccountsLoadTime = null;
  }

  Future<void> _loadAccountsProfileData() async {
    if (_isLoadingAccounts) return;
    _isLoadingAccounts = true;

    try {
      final List<Account> accounts = await getAccounts();
      final UserProfileDataNotifier userProfileDataNotifier = ref.read(
        userProfileDataProvider.notifier,
      );
      final List<Future<ContactModel>> accountsProfileDataFutures =
          accounts
              .map((account) => userProfileDataNotifier.getUserProfileData(account.pubkey))
              .toList();
      final List<ContactModel> accountsProfileData = await Future.wait(accountsProfileDataFutures);

      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _accountsProfileData = accountsProfileData;
        _lastAccountsLoadTime = DateTime.now();
      });
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to load accounts');
      }
    } finally {
      _isLoadingAccounts = false;
    }
  }

  Future<void> _loadPackageInfo() async {
    if (_isLoadingPackageInfo || _packageInfo != null) return;
    _isLoadingPackageInfo = true;

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _packageInfo = packageInfo;
      });
    } catch (e) {
      // Silently handle error - version info is not critical
      debugPrint('Failed to load package info: $e');
    } finally {
      _isLoadingPackageInfo = false;
    }
  }

  Future<void> _switchAccount(String accountPubkey) async {
    try {
      await ref.read(activePubkeyProvider.notifier).setActivePubkey(accountPubkey);

      if (mounted) {
        ref.showSuccessToast('Account switched successfully');
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('Failed to switch account: $e');
      }
    }
  }

  Future<void> _showAccountSwitcher({
    bool isDismissible = true,
    bool showSuccessToast = false,
  }) async {
    if (_accounts.isEmpty) {
      await _loadAccountsProfileDataIfNeeded();
    }

    if (!mounted) return;

    SwitchProfileBottomSheet.show(
      context: context,
      profiles: _accountsProfileData,
      isDismissible: isDismissible,
      showSuccessToast: showSuccessToast,
      onProfileSelected: (selectedProfile) async {
        await _switchAccount(selectedProfile.publicKey);
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
        await _loadAccountsProfileData();

        if (mounted) {
          await _showAccountSwitcher(isDismissible: false, showSuccessToast: true);
        }
      } else {
        ref.showSuccessToast('Account signed out. Switched to the other available account.');
        await _loadAccountsProfileData();
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
        leading: RepaintBoundary(
          child: IconButton(
            onPressed: () => context.pop(),
            icon: WnImage(
              AssetsPaths.icChevronLeft,
              width: 24.w,
              height: 24.w,
              color: context.colors.solidPrimary,
            ),
          ),
        ),
        title: RepaintBoundary(
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: context.colors.solidPrimary,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(vertical: 24.h),
        children: [
          RepaintBoundary(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  const ActiveAccountTile(),
                  SizedBox(height: 12.h),
                  WnFilledButton(
                    label: 'Switch Account',
                    size: WnButtonSize.small,
                    visualState: WnButtonVisualState.secondary,
                    onPressed: () async => await _showAccountSwitcher(),
                    suffixIcon: WnImage(
                      AssetsPaths.icArrowsVertical,
                      color: context.colors.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),

          Container(
            height: 1,
            color: context.colors.baseMuted,
          ),

          RepaintBoundary(
            child: _SettingsSection(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              children: [
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

          Container(
            height: 1,
            color: context.colors.baseMuted,
            margin: EdgeInsets.symmetric(vertical: 12.h),
          ),

          RepaintBoundary(
            child: _SettingsSection(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
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

          Container(
            height: 1,
            color: context.colors.baseMuted,
            margin: EdgeInsets.symmetric(vertical: 12.h),
          ),

          RepaintBoundary(
            child: _SettingsSection(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
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

          SizedBox(height: 32.h),
          if (_packageInfo != null)
            RepaintBoundary(
              child: Center(
                child: Text(
                  'Version ${_packageInfo!.version}+${_packageInfo!.buildNumber}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w400,
                    color: context.colors.mutedForeground,
                  ),
                ),
              ),
            ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

/// Optimized settings section widget to reduce widget tree depth
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.children,
    this.padding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        children: children,
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
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Row(
            children: [
              RepaintBoundary(
                child: WnImage(
                  assetPath,
                  size: 24.w,
                  color: foregroundColor ?? context.colors.primary,
                ),
              ),
              SizedBox(width: 12.w),
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
      ),
    );
  }
}
