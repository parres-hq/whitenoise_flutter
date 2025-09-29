import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/domain/services/background_sync_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

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
      ref.showErrorToast('No active account found');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (dialogContext) => WnDialog(
            title: 'Delete All Key Packages',
            content:
                'This will delete all key packages for the active account. Other users won\'t be able to invite you to new encrypted conversations until you generate new key packages. This action cannot be undone.',
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
                    visualState: WnButtonVisualState.destructive,
                    size: WnButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    label: 'Delete',
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
      ref.showSuccessToast('Deleted $deletedCount key packages successfully');

      // Clear the displayed key packages if they were being shown
      if (_showKeyPackages) {
        setState(() {
          _keyPackages = [];
          _showKeyPackages = false;
        });
      }
    } catch (e) {
      ref.showErrorToast('Failed to delete key packages: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchKeyPackages() async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('No active account found');
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
      ref.showSuccessToast('Fetched ${keyPackages.length} key packages');
    } catch (e) {
      ref.showErrorToast('Failed to fetch key packages: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _publishKeyPackage() async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('No active account found');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await accounts_api.publishAccountKeyPackage(
        accountPubkey: activePubkey,
      );
      ref.showSuccessToast('Key package published successfully');

      // Refresh the key packages list if it's currently shown
      if (_showKeyPackages) {
        await _fetchKeyPackages();
      }
    } catch (e) {
      ref.showErrorToast('Failed to publish key package: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteKeyPackage(String keyPackageId, int index) async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('No active account found');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder:
          (dialogContext) => WnDialog(
            title: 'Delete Key Package',
            content:
                'This will delete key package #${index + 1}. Other users won\'t be able to use this key package to invite you to new encrypted conversations. This action cannot be undone.',
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
                    visualState: WnButtonVisualState.destructive,
                    size: WnButtonSize.small,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    label: 'Delete',
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
      ref.showSuccessToast('Key package deleted successfully');

      // Refresh the key packages list
      await _fetchKeyPackages();
    } catch (e) {
      ref.showErrorToast('Failed to delete key package: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testBackgroundTask(String taskName) async {
    setState(() => _isLoading = true);
    try {
      await BackgroundSyncService.triggerTask(taskName);
      ref.showSuccessToast('Background task "$taskName" triggered successfully');
    } catch (e) {
      ref.showErrorToast('Failed to trigger background task: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerBackgroundTasks() async {
    setState(() => _isLoading = true);
    try {
      await BackgroundSyncService.registerAllTasks();
      ref.showSuccessToast('Background tasks registered successfully');
    } catch (e) {
      ref.showErrorToast('Failed to register background tasks: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelBackgroundTasks() async {
    setState(() => _isLoading = true);
    try {
      await BackgroundSyncService.cancelAllTasks();
      ref.showSuccessToast('Background tasks cancelled successfully');
    } catch (e) {
      ref.showErrorToast('Failed to cancel background tasks: $e');
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
                width: 24.w,
                height: 24.w,
                color: context.colors.solidPrimary,
              ),
            ),
          ),
          title: RepaintBoundary(
            child: Text(
              'Developer Settings',
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
                                    'Key Package Management',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  Gap(10.h),
                                  WnFilledButton(
                                    label: 'Publish new key package',
                                    onPressed: _isLoading ? null : _publishKeyPackage,
                                    loading: _isLoading,
                                  ),
                                  Gap(8.h),
                                  WnFilledButton(
                                    label: 'Inspect relay key packages',
                                    onPressed: _isLoading ? null : _fetchKeyPackages,
                                    loading: _isLoading && !_showKeyPackages,
                                  ),
                                  Gap(8.h),
                                  WnFilledButton(
                                    label: 'Delete all key packages from relays',
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
                                'Key Packages (${_keyPackages.length})',
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
                                          'No key packages found',
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
                                Expanded(
                                  child: RepaintBoundary(
                                    child: ListView.separated(
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
                                ),
                            ],
                            Gap(24.h),
                            RepaintBoundary(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Background Sync Testing',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                  Gap(10.h),
                                  WnFilledButton(
                                    label: 'Register Background Tasks',
                                    onPressed: _isLoading ? null : _registerBackgroundTasks,
                                    loading: _isLoading,
                                  ),
                                  Gap(8.h),
                                  WnFilledButton(
                                    label: 'Cancel All Background Tasks',
                                    visualState: WnButtonVisualState.destructive,
                                    onPressed: _isLoading ? null : _cancelBackgroundTasks,
                                    loading: _isLoading,
                                    labelTextStyle: WnButtonSize.large.textStyle().copyWith(
                                      color: context.colors.solidNeutralWhite,
                                    ),
                                  ),
                                  Gap(8.h),
                                  Text(
                                    'Test Individual Tasks:',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.mutedForeground,
                                    ),
                                  ),
                                  Gap(4.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: WnFilledButton(
                                          label: 'Messages Sync',
                                          size: WnButtonSize.small,
                                          onPressed:
                                              _isLoading
                                                  ? null
                                                  : () => _testBackgroundTask(
                                                    BackgroundSyncService.messagesSyncTask,
                                                  ),
                                          loading: _isLoading,
                                        ),
                                      ),
                                      Gap(8.w),
                                      Expanded(
                                        child: WnFilledButton(
                                          label: 'Invites Sync',
                                          size: WnButtonSize.small,
                                          onPressed:
                                              _isLoading
                                                  ? null
                                                  : () => _testBackgroundTask(
                                                    BackgroundSyncService.invitesSyncTask,
                                                  ),
                                          loading: _isLoading,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Gap(8.h),
                                  WnFilledButton(
                                    label: 'Metadata Refresh',
                                    size: WnButtonSize.small,
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : () => _testBackgroundTask(
                                              BackgroundSyncService.metadataRefreshTask,
                                            ),
                                    loading: _isLoading,
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
      // This reduces rasterization cost significantly
      decoration: BoxDecoration(
        color: context.colors.avatarSurface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.3),
            width: 0.5, // Thinner border for better performance
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
                    'Key Package #${index + 1}',
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
              'ID: ${keyPackage.id}',
              style: TextStyle(
                fontSize: 12.sp,
                color: context.colors.mutedForeground,
                fontFamily: 'Courier',
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Created at: ${keyPackage.createdAt.toIso8601String()}',
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
