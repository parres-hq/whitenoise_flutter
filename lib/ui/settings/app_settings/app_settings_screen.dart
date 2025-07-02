import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/theme_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/ui/core/ui/whitenoise_dialog.dart';

class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  Future<void> _deleteAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (dialogContext) => WhitenoiseDialog(
            title: 'Delete app app data',
            content: 'This will erase every profile, key, and local files. This can\'t be undone.',
            actions: Row(
              children: [
                Expanded(
                  child: AppFilledButton(
                    title: 'Cancel',
                    visualState: AppButtonVisualState.secondary,
                    size: AppButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                Gap(8.w),
                Expanded(
                  child: AppFilledButton.child(
                    visualState: AppButtonVisualState.error,
                    size: AppButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      'Delete',
                      style: AppButtonSize.small.textStyle().copyWith(
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

    try {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await deleteAllData();

      if (!context.mounted) return;
      ref.read(authProvider.notifier).setUnAuthenticated();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data deleted successfully')),
      );
      context.go(Routes.home);
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider).themeMode;

    String themeText;
    IconData themeIcon;
    switch (themeMode) {
      case ThemeMode.system:
        // Currently in Auto mode, next is Light mode
        themeText = 'Auto Mode';
        themeIcon = CarbonIcons.sun;
        break;
      case ThemeMode.light:
        // Currently in Light mode, next is Dark mode
        themeText = 'Light Mode';
        themeIcon = CarbonIcons.moon;
        break;
      case ThemeMode.dark:
        // Currently in Dark mode, next is Auto mode
        themeText = 'Dark Mode';
        themeIcon = CarbonIcons.brightness_contrast;
        break;
    }

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
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                bottom: 24.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Gap(24.h),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Icon(
                          CarbonIcons.chevron_left,
                          size: 24.w,
                          color: context.colors.primary,
                        ),
                      ),
                      Gap(16.w),
                      Text(
                        'App Settings',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  Gap(40.h),
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                  Gap(16.h),
                  AppFilledButton.child(
                    onPressed: () {
                      final nextMode = switch (themeMode) {
                        ThemeMode.system => ThemeMode.light,
                        ThemeMode.light => ThemeMode.dark,
                        ThemeMode.dark => ThemeMode.system,
                      };
                      ref.read(themeProvider.notifier).setThemeMode(nextMode);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          themeText,
                          style: AppButtonSize.large.textStyle().copyWith(
                            color: context.colors.primaryForeground,
                          ),
                        ),
                        Gap(8.w),
                        Icon(
                          themeIcon,
                          size: 20.w,
                          color: context.colors.primaryForeground,
                        ),
                      ],
                    ),
                  ),
                  Gap(32.h),
                  Text(
                    'Delete App Data',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                  Gap(16.h),
                  AppFilledButton.child(
                    visualState: AppButtonVisualState.error,
                    onPressed: () => _deleteAllData(context, ref),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Delete All Data',
                          style: AppButtonSize.large.textStyle().copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Gap(8.w),
                        Icon(
                          CarbonIcons.trash_can,
                          size: 20.w,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
