import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/settings/developer/background_sync_screen.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class DeveloperSettingsScreen extends ConsumerStatefulWidget {
  const DeveloperSettingsScreen({super.key});

  @override
  ConsumerState<DeveloperSettingsScreen> createState() => _DeveloperSettingsScreenState();

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DeveloperSettingsScreen(),
      ),
    );
  }
}

class _DeveloperSettingsScreenState extends ConsumerState<DeveloperSettingsScreen> {
  bool _isLoading = false;
  List<accounts_api.FlutterEvent> _keyPackages = [];
  bool _showKeyPackages = false;

  Future<void> _deleteAllKeyPackages() async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('settings.noActiveAccountFound'.tr());
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (dialogContext) => WnDialog(
            title: 'settings.deleteAllKeyPackagesTitle'.tr(),
            content: 'settings.deleteAllKeyPackagesDescription'.tr(),
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
                    label: 'shared.delete'.tr(),
                    labelTextStyle: WnButtonSize.small.textStyle().copyWith(
                      color: context.colors.solidNeutralWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final deletedCount = await accounts_api.deleteAccountKeyPackages(
        accountPubkey: activePubkey,
      );
      ref.showSuccessToast(
        'settings.deletedKeyPackagesSuccess'.tr({'count': deletedCount}),
      );

      // Clear the displayed key packages if they were being shown
      if (_showKeyPackages) {
        setState(() {
          _keyPackages = [];
          _showKeyPackages = false;
        });
      }
    } catch (e) {
      ref.showErrorToast('${'settings.failedToDeleteKeyPackages'.tr()}: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchKeyPackages() async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('settings.noActiveAccountFound'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      final keyPackages = await accounts_api.accountKeyPackages(
        accountPubkey: activePubkey,
      );
      setState(() {
        _keyPackages = keyPackages;
        _showKeyPackages = true;
      });
      ref.showSuccessToast(
        'settings.fetchedKeyPackagesSuccess'.tr().replaceAll(
          '{count}',
          keyPackages.length.toString(),
        ),
      );
    } catch (e) {
      ref.showErrorToast('${'settings.failedToFetchKeyPackages'.tr()}: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _publishKeyPackage() async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('settings.noActiveAccountFound'.tr());
      return;
    }

    setState(() => _isLoading = true);

    try {
      await accounts_api.publishAccountKeyPackage(
        accountPubkey: activePubkey,
      );
      ref.showSuccessToast('settings.keyPackagePublishedSuccess'.tr());

      // Refresh the key packages list if it's currently shown
      if (_showKeyPackages) {
        await _fetchKeyPackages();
      }
    } catch (e) {
      ref.showErrorToast('${'settings.failedToPublishKeyPackage'.tr()}: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteKeyPackage(String keyPackageId, int index) async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('settings.noActiveAccountFound'.tr());
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (dialogContext) => WnDialog(
            title: 'settings.deleteKeyPackageTitle'.tr(),
            content: 'settings.deleteKeyPackageDescription'.tr().replaceAll(
              '{number}',
              (index + 1).toString(),
            ),
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
                    label: 'shared.delete'.tr(),
                    labelTextStyle: WnButtonSize.small.textStyle().copyWith(
                      color: context.colors.solidNeutralWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await accounts_api.deleteAccountKeyPackage(
        accountPubkey: activePubkey,
        keyPackageId: keyPackageId,
      );
      ref.showSuccessToast('settings.keyPackageDeletedSuccess'.tr());

      // Refresh the key packages list
      await _fetchKeyPackages();
    } catch (e) {
      ref.showErrorToast('${'settings.failedToDeleteKeyPackage'.tr()}: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.colors.neutral,
        appBar: WnAppBar(
          automaticallyImplyLeading: false,
          leading: RepaintBoundary(
            child: IconButton(
              onPressed: () => context.pop(),
              icon: WnImage(
                AssetsPaths.icChevronLeft,
                size: 15.w,
                color: context.colors.solidPrimary,
              ),
            ),
          ),
          title: RepaintBoundary(
            child: Text(
              'settings.developerSettings'.tr(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.solidPrimary,
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: ColoredBox(
            color: context.colors.neutral,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RepaintBoundary(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Key Package Management
                                  Text(
                                    'settings.keyPackageManagement'.tr(),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  Gap(10.h),
                                  WnFilledButton(
                                    label: 'settings.publishNewKeyPackage'.tr(),
                                    onPressed: _isLoading ? null : _publishKeyPackage,
                                    loading: _isLoading,
                                  ),
                                  Gap(8.h),
                                  WnFilledButton(
                                    label: 'settings.inspectRelayKeyPackages'.tr(),
                                    onPressed: _isLoading ? null : _fetchKeyPackages,
                                    loading: _isLoading && !_showKeyPackages,
                                  ),
                                  Gap(8.h),
                                  WnFilledButton(
                                    label: 'settings.deleteAllKeyPackagesFromRelays'.tr(),
                                    visualState: WnButtonVisualState.destructive,
                                    onPressed: _isLoading ? null : _deleteAllKeyPackages,
                                    loading: _isLoading && _showKeyPackages,
                                    labelTextStyle: WnButtonSize.large.textStyle().copyWith(
                                      color: context.colors.solidNeutralWhite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_showKeyPackages) ...[
                              Gap(24.h),
                              Text(
                                'settings.keyPackagesCount'.tr().replaceAll(
                                  '{count}',
                                  _keyPackages.length.toString(),
                                ),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                              Gap(12.h),
                              if (_keyPackages.isEmpty)
                                RepaintBoundary(
                                  child: Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: context.colors.avatarSurface,

                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: context.colors.border.withValues(alpha: 0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        WnImage(
                                          AssetsPaths.icInformation,
                                          size: 20.w,
                                          color: context.colors.mutedForeground,
                                        ),
                                        SizedBox(width: 12.w),
                                        Text(
                                          'settings.noKeyPackagesFound'.tr(),
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: context.colors.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                RepaintBoundary(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _keyPackages.length,
                                    separatorBuilder: (context, index) => SizedBox(height: 8.h),
                                    itemBuilder: (context, index) {
                                      final keyPackage = _keyPackages[index];
                                      return RepaintBoundary(
                                        child: _KeyPackageItem(
                                          keyPackage: keyPackage,
                                          index: index,
                                          isLoading: _isLoading,
                                          onDelete: () => _deleteKeyPackage(keyPackage.id, index),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                            Gap(24.h),
                            RepaintBoundary(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'settings.backgroundServices'.tr(),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.primary,
                                    ),
                                  ),

                                  Gap(10.h),
                                  WnFilledButton(
                                    label: 'settings.backgroundSyncService'.tr(),
                                    onPressed: () => BackgroundSyncScreen.show(context),
                                  ),
                                ],
                              ),
                            ),
                            Gap(MediaQuery.of(context).padding.bottom),
                          ],
                        ),
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

/// Optimized key package item widget with reduced rasterization cost
class _KeyPackageItem extends StatelessWidget {
  const _KeyPackageItem({
    required this.keyPackage,
    required this.index,
    required this.isLoading,
    required this.onDelete,
  });

  final accounts_api.FlutterEvent keyPackage;
  final int index;
  final bool isLoading;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.colors.avatarSurface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.3),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(6.r),
        ),
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                RepaintBoundary(
                  child: WnImage(
                    AssetsPaths.icPassword,
                    size: 16.w,
                    color: context.colors.primary,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'settings.keyPackageNumber'.tr({'number': index + 1}),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                  ),
                ),

                RepaintBoundary(
                  child: InkWell(
                    onTap: isLoading ? null : onDelete,
                    borderRadius: BorderRadius.circular(4.r),
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: WnImage(
                        AssetsPaths.icDelete,
                        size: 16.w,
                        color:
                            isLoading
                                ? context.colors.mutedForeground.withValues(alpha: 0.5)
                                : context.colors.destructive,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'settings.keyPackageId'.tr({'id': keyPackage.id}),
              style: TextStyle(
                fontSize: 12.sp,
                color: context.colors.mutedForeground,
                fontFamily: 'Courier',
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'settings.keyPackageCreatedAt'.tr().replaceAll(
                '{date}',
                keyPackage.createdAt.toIso8601String(),
              ),
              style: TextStyle(
                fontSize: 12.sp,
                color: context.colors.mutedForeground,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
