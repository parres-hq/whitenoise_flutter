import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/polling_provider.dart';
import 'package:whitenoise/config/providers/theme_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api.dart' as wn_api;
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/widgets/wn_settings_screen_wrapper.dart';
import 'package:whitenoise/ui/widgets/language_selector_dropdown.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  static final _logger = Logger('AppSettingsScreen');

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (dialogContext) => WnDialog(
            title: 'settings.deleteAppDataTitle'.tr(),
            content: 'settings.deleteAppDataDescription'.tr(),
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
                    visualState: WnButtonVisualState.destructive,
                    size: WnButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    label: 'settings.delete'.tr(),
                    labelTextStyle: WnButtonSize.small.textStyle().copyWith(
                      color: context.colors.solidNeutralWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    // If user didn't confirm, return early
    if (confirmed != true) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      _logger.info('🔥 Starting delete all data process...');

      // First stop any ongoing operations
      try {
        _logger.info('🛑 Stopping polling...');
        ref.read(pollingProvider.notifier).stopPolling();
        _logger.info('✅ Polling stopped');
      } catch (e) {
        _logger.warning('⚠️ Error stopping polling: $e');
        // Continue anyway
      }

      // Add timeout to prevent hanging
      _logger.info('🗑️ Calling backend deleteAllData...');
      await wn_api.deleteAllData().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Delete operation timed out after 30 seconds');
        },
      );
      _logger.info('✅ Backend data deleted successfully');

      if (!context.mounted) return;

      // Clear all provider states with individual try-catch
      _logger.info('🧹 Clearing provider states...');
      try {
        ref.invalidate(pollingProvider);
        _logger.info('✅ Polling provider invalidated');
      } catch (e) {
        _logger.warning('⚠️ Error invalidating polling provider: $e');
      }

      try {
        ref.invalidate(chatProvider);
        _logger.info('✅ Chat provider invalidated');
      } catch (e) {
        _logger.warning('⚠️ Error invalidating chat provider: $e');
      }

      try {
        ref.invalidate(groupsProvider);
        _logger.info('✅ Groups provider invalidated');
      } catch (e) {
        _logger.warning('⚠️ Error invalidating groups provider: $e');
      }

      try {
        ref.invalidate(activeAccountProvider);
        _logger.info('✅ Active account provider invalidated');
      } catch (e) {
        _logger.warning('⚠️ Error invalidating active account provider: $e');
      }

      try {
        ref.invalidate(followsProvider);
        _logger.info('✅ Follows provider invalidated');
      } catch (e) {
        _logger.warning('⚠️ Error invalidating follows provider: $e');
      }
      try {
        ref.invalidate(activePubkeyProvider);
        _logger.info('✅ Active pubkey provider invalidated');
      } catch (e) {
        _logger.warning('⚠️ Error invalidating active pubkey provider: $e');
      }

      // Set authentication state to false - this should be last
      try {
        _logger.info('🔓 Setting unauthenticated state...');
        ref.read(authProvider.notifier).setUnAuthenticated();
        _logger.info('✅ Authentication state cleared');
      } catch (e) {
        _logger.warning('⚠️ Error setting unauthenticated: $e');
        // Try to invalidate auth provider as fallback
        ref.invalidate(authProvider);
      }

      _logger.info('🏠 Navigating to home...');
      Navigator.of(context).pop(); // Close loading dialog
      context.go(Routes.home);
      _logger.info('✅ Delete all data completed successfully');
    } catch (e, stackTrace) {
      _logger.severe('❌ Error in delete all data: $e', e, stackTrace);

      if (!context.mounted) return;

      Navigator.of(context).pop(); // Close loading dialog
      ref.showErrorToast('Failed to delete data: $e', durationMs: 5000);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider).themeMode;

    return WnSettingsScreenWrapper(
      title: LocalizedText(
        'settings.appSettings',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: context.colors.solidPrimary,
        ),
      ),
      safeAreaBottom: false,
      body: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 16.w,
                          right: 16.w,
                          bottom: 24.w,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              'settings.theme',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                            Gap(10.h),
                            _ThemeDropdown(
                              currentTheme: themeMode,
                              onThemeChanged: (newMode) {
                                ref.read(themeProvider.notifier).setThemeMode(newMode);
                              },
                            ),
                            Gap(24.h),
                            LocalizedText(
                              'settings.language',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                            Gap(10.h),
                            const LanguageSelectorDropdown(),
                            Gap(24.h),
                            LocalizedText(
                              'settings.dangerZone',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                            Gap(10.h),
                            WnFilledButton(
                              label: 'settings.deleteAllData'.tr(),
                              labelTextStyle: WnButtonSize.large.textStyle().copyWith(
                                color: context.colors.solidNeutralWhite,
                              ),
                              visualState: WnButtonVisualState.destructive,
                              onPressed: () => _deleteAllData(context, ref),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ThemeDropdown extends StatefulWidget {
  final ThemeMode currentTheme;
  final ValueChanged<ThemeMode> onThemeChanged;

  const _ThemeDropdown({
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<_ThemeDropdown> createState() => _ThemeDropdownState();
}

class _ThemeDropdownState extends State<_ThemeDropdown> {
  bool isExpanded = false;

  String getThemeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'settings.themeSystem'.tr();
      case ThemeMode.light:
        return 'settings.themeLight'.tr();
      case ThemeMode.dark:
        return 'settings.themeDark'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Container(
            height: 56.h,
            decoration: BoxDecoration(
              color: context.colors.avatarSurface,
              border: Border.all(color: context.colors.border),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 16.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getThemeText(widget.currentTheme),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: context.colors.primary,
                  ),
                ),
                WnImage(
                  isExpanded ? AssetsPaths.icChevronUp : AssetsPaths.icChevronDown,
                  size: 20.w,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          Gap(8.h),
          Container(
            decoration: BoxDecoration(
              color: context.colors.avatarSurface,
              border: Border.all(
                color: context.colors.border,
                width: 1.w,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ThemeOption(
                  text: 'settings.themeSystem'.tr(),
                  isSelected: widget.currentTheme == ThemeMode.system,
                  onTap: () {
                    widget.onThemeChanged(ThemeMode.system);
                    setState(() {
                      isExpanded = false;
                    });
                  },
                ),
                _ThemeOption(
                  text: 'settings.themeLight'.tr(),
                  isSelected: widget.currentTheme == ThemeMode.light,
                  onTap: () {
                    widget.onThemeChanged(ThemeMode.light);
                    setState(() {
                      isExpanded = false;
                    });
                  },
                ),
                _ThemeOption(
                  text: 'settings.themeDark'.tr(),
                  isSelected: widget.currentTheme == ThemeMode.dark,
                  onTap: () {
                    widget.onThemeChanged(ThemeMode.dark);
                    setState(() {
                      isExpanded = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(6.w),
        padding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 16.h,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? context.colors.primary.withValues(alpha: 0.1)
                  : context.colors.avatarSurface,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? context.colors.primary : context.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
