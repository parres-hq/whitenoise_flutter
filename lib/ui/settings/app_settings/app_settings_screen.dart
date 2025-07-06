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
            child: Column(
              children: [
                Expanded(
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
                          Gap(32.h),
                          Text(
                            'Theme',
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
                          Gap(16.h),
                          Text(
                            'Delete App Data',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                          Gap(10.h),
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
              ],
            ),
          ),
        ),
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
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
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
                Icon(
                  isExpanded ? CarbonIcons.chevron_up : CarbonIcons.chevron_down,
                  color: context.colors.primary,
                  size: 20.w,
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
                  text: 'System',
                  isSelected: widget.currentTheme == ThemeMode.system,
                  onTap: () {
                    widget.onThemeChanged(ThemeMode.system);
                    setState(() {
                      isExpanded = false;
                    });
                  },
                ),
                _ThemeOption(
                  text: 'Light',
                  isSelected: widget.currentTheme == ThemeMode.light,
                  onTap: () {
                    widget.onThemeChanged(ThemeMode.light);
                    setState(() {
                      isExpanded = false;
                    });
                  },
                ),
                _ThemeOption(
                  text: 'Dark',
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
