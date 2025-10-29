import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' show Account, getAccounts;
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/widgets/wn_settings_screen_wrapper.dart';
import 'package:whitenoise/ui/settings/developer/developer_settings_screen.dart';
import 'package:whitenoise/ui/settings/profile/switch_profile_bottom_sheet.dart';
import 'package:whitenoise/ui/settings/widgets/active_account_tile.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class GeneralSettingsScreen extends ConsumerStatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  ConsumerState<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends ConsumerState<GeneralSettingsScreen> {
  PackageInfo? _packageInfo;
  bool _isLoadingPackageInfo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPackageInfo();
    });
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
        ref.showSuccessToast('settings.accountSwitchedSuccessfully'.tr());
      }
    } catch (e) {
      if (mounted) {
        ref.showErrorToast('${'settings.failedToSwitchAccount'.tr()}: $e');
      }
    }
  }

  Future<void> _showAccountSwitcher({
    bool isDismissible = true,
    bool showSuccessToast = false,
  }) async {
    if (!mounted) return;

    SwitchProfileBottomSheet.show(
      context: context,
      isDismissible: isDismissible,
      showSuccessToast: showSuccessToast,
      onProfileSelected: (UserProfile selectedProfile) async {
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
            title: 'settings.signOutTitle'.tr(),
            content: 'settings.signOutWarning'.tr(),
            actions: Row(
              children: [
                Expanded(
                  child: WnFilledButton(
                    label: 'shared.cancel'.tr(),
                    visualState: WnButtonVisualState.secondary,
                    size: WnButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: WnFilledButton(
                    label: 'settings.signOut'.tr(),
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

    if (!mounted) return;

    // Clear all draft messages before logout
    await DraftMessageService().clearAllDrafts();

    await authNotifier.logoutCurrentAccount();

    if (!mounted) return;

    // Check the final auth state after logout
    final finalAuthState = ref.read(authProvider);

    if (finalAuthState.error != null) {
      ref.showErrorToast(finalAuthState.error!);
      return;
    }

    if (finalAuthState.isAuthenticated) {
      try {
        final List<Account> accounts = await getAccounts();
        final hasMultipleAccounts = accounts.length > 1;

        if (hasMultipleAccounts) {
          if (mounted) {
            await _showAccountSwitcher(isDismissible: false, showSuccessToast: true);
          }
        } else {
          ref.showSuccessToast('settings.accountSignedOutSwitched'.tr());
        }
      } catch (e) {
        ref.showErrorToast('settings.failedToCheckAccountsAfterLogout'.tr());
      }
    } else {
      ref.showSuccessToast('settings.signedOutSuccessfully'.tr());
      if (mounted) {
        context.go(Routes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WnSettingsScreenWrapper(
      title: 'settings.title'.tr(),
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
                    label: 'ui.switchAccount'.tr(),
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
                  text: 'settings.editProfile'.tr(),
                  onTap: () => context.push('${Routes.settings}/profile'),
                ),
                SettingsListTile(
                  assetPath: AssetsPaths.icPassword,
                  text: 'settings.profileKeys'.tr(),
                  onTap: () => context.push('${Routes.settings}/keys'),
                ),
                SettingsListTile(
                  assetPath: AssetsPaths.icDataVis3,
                  text: 'settings.networkRelays'.tr(),
                  onTap: () => context.push('${Routes.settings}/network'),
                ),
                SettingsListTile(
                  assetPath: AssetsPaths.icLogout,
                  text: 'settings.signOut'.tr(),
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
                  text: 'settings.appSettings'.tr(),
                  onTap: () => context.push('${Routes.settings}/app_settings'),
                ),
                SettingsListTile(
                  assetPath: AssetsPaths.icFavorite,
                  text: 'settings.donateToWhiteNoise'.tr(),
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
                  text: 'settings.developerSettings'.tr(),
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
                  '${'settings.version'.tr()} ${_packageInfo!.version}+${_packageInfo!.buildNumber}',
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
