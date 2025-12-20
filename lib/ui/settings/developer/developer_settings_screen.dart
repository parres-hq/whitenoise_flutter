import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/domain/services/nip55_service.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/api/nip55.dart' as nip55_api;
import 'package:whitenoise/src/rust/api/relays.dart' as relays_api;
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_dialog.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/widgets/wn_settings_screen_wrapper.dart';
import 'package:whitenoise/ui/settings/developer/background_sync_screen.dart';
import 'package:whitenoise/utils/error_handling.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/public_key_validation_extension.dart';

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
  static final Logger _logger = Logger('DeveloperSettingsScreen');
  bool _isPublishingKeyPackage = false;
  bool _isFetchingKeyPackages = false;
  bool _isDeletingAllKeyPackages = false;
  bool _isLoading = false;
  List<accounts_api.FlutterEvent> _keyPackages = [];
  bool _showKeyPackages = false;

  bool get _isAnyOperationInProgress =>
      _isPublishingKeyPackage || _isFetchingKeyPackages || _isDeletingAllKeyPackages;

  Future<bool> _hasKeyPackageRelaysConfigured({required String activePubkey}) async {
    // If the user has no key package relays configured, key package operations that
    // require relay interaction cannot succeed.
    final keyPackageType = await relays_api.relayTypeKeyPackage();
    final relays = await accounts_api.accountRelays(
      pubkey: activePubkey,
      relayType: keyPackageType,
    );
    return relays.isNotEmpty;
  }

  Future<void> _deleteAllKeyPackages() async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('settings.noActiveAccountFound'.tr());
      return;
    }

    // If the user has no key package relays configured, deleting from relays cannot succeed.
    // Fail fast with a user-friendly hint rather than throwing a raw Exception.
    try {
      final hasRelays = await _hasKeyPackageRelaysConfigured(activePubkey: activePubkey);
      if (!hasRelays) {
        ref.showErrorToast(
          'errors.relayConfigurationHelp'.tr(),
        );
        return;
      }
    } catch (e, st) {
      final message = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage: 'settings.failedToDeleteKeyPackages'.tr(),
        context: 'deleteAllKeyPackages/precheck',
      );
      ref.showErrorToast(message);
      return;
    }

    if (!mounted) return;

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

    if (!mounted) return;
    setState(() => _isDeletingAllKeyPackages = true);

    try {
      final deletedCount = await accounts_api.deleteAccountKeyPackages(
        accountPubkey: activePubkey,
      );
      ref.showSuccessToast(
        'settings.deletedKeyPackagesSuccess'.tr({'count': deletedCount.toString()}),
      );

      // Clear the displayed key packages if they were being shown
      if (_showKeyPackages) {
        setState(() {
          _keyPackages = [];
          _showKeyPackages = false;
        });
      }
    } catch (e, st) {
      final message = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage: 'settings.failedToDeleteKeyPackages'.tr(),
        context: 'deleteAllKeyPackages',
      );
      ref.showErrorToast(message);
    } finally {
      if (mounted) {
        setState(() => _isDeletingAllKeyPackages = false);
      }
    }
  }

  Future<void> _fetchKeyPackages({bool showLoading = true}) async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('settings.noActiveAccountFound'.tr());
      return;
    }

    if (showLoading) {
      setState(() => _isFetchingKeyPackages = true);
    }

    try {
      final keyPackages = await accounts_api.accountKeyPackages(
        accountPubkey: activePubkey,
      );
      setState(() {
        _keyPackages = keyPackages;
        _showKeyPackages = true;
      });
      if (showLoading) {
        ref.showSuccessToast(
          'settings.fetchedKeyPackagesSuccess'.tr().replaceAll(
            '{count}',
            keyPackages.length.toString(),
          ),
        );
      }
    } catch (e, st) {
      if (showLoading) {
        final message = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
          error: e,
          stackTrace: st,
          fallbackMessage: 'settings.failedToFetchKeyPackages'.tr(),
          context: 'fetchKeyPackages',
        );
        ref.showErrorToast(message);
      }
    } finally {
      if (mounted && showLoading) {
        setState(() => _isFetchingKeyPackages = false);
      }
    }
  }

  Future<void> _publishKeyPackage() async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    if (activePubkey.isEmpty) {
      ref.showErrorToast('settings.noActiveAccountFound'.tr());
      return;
    }

    setState(() => _isPublishingKeyPackage = true);

    try {
      await accounts_api.publishAccountKeyPackage(
        accountPubkey: activePubkey,
      );
      ref.showSuccessToast('settings.keyPackagePublishedSuccess'.tr());

      // Refresh the key packages list if it's currently shown
      if (_showKeyPackages) {
        await _fetchKeyPackages(showLoading: false);
      }
    } catch (e, st) {
      final message = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage: 'settings.failedToPublishKeyPackage'.tr(),
        context: 'publishKeyPackage',
      );
      ref.showErrorToast(message);
    } finally {
      if (mounted) {
        setState(() => _isPublishingKeyPackage = false);
      }
    }
  }

  Future<void> _deleteKeyPackage(String keyPackageId, int index) async {
    final activePubkey = ref.read(activePubkeyProvider) ?? '';
    _logger.info('Delete key package start: id=$keyPackageId, index=$index, pubkey=$activePubkey');

    if (activePubkey.isEmpty) {
      _logger.warning('No active pubkey for key package deletion');
      ref.showErrorToast('settings.noActiveAccountFound'.tr());
      return;
    }

    try {
      _logger.fine('Checking key package relays');
      final hasRelays = await _hasKeyPackageRelaysConfigured(activePubkey: activePubkey);
      _logger.fine('Has key package relays: $hasRelays');
      if (!hasRelays) {
        _logger.warning('No key package relays configured');
        ref.showErrorToast('errors.relayConfigurationHelp'.tr());
        return;
      }
    } catch (e, st) {
      _logger.warning('Error checking relays', e, st);
      final message = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage: 'settings.failedToDeleteKeyPackage'.tr(),
        context: 'deleteKeyPackage/precheck',
      );
      ref.showErrorToast(message);
      return;
    }

    if (!mounted) return;

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
      _logger.fine('Checking if NIP55 account');
      try {
        final resultJson = await Nip55Service.callNip55Method(
          method: 'get_public_key',
          params: '{}',
        );
        final result = jsonDecode(resultJson) as Map<String, dynamic>;
        final pubkeyNpub = result['result'] as String?;

        if (pubkeyNpub != null && pubkeyNpub.isValidNpubPublicKey) {
          final signerHexPubkey = PubkeyFormatter(pubkey: pubkeyNpub).toHex();
          _logger.fine('NIP55 signer pubkey: $signerHexPubkey, active pubkey: $activePubkey');

          if (signerHexPubkey != null &&
              signerHexPubkey.toLowerCase() == activePubkey.toLowerCase()) {
            _logger.info('This is a NIP55 account - enabling signer');
            try {
              await nip55_api.enableNip55Signer(pubkey: activePubkey);
              _logger.info('NIP55 signer enabled successfully before delete');
            } catch (e, st) {
              _logger.warning('Failed to enable NIP55 signer before delete', e, st);
            }
          } else {
            _logger.fine('Not a NIP55 account (pubkeys don\'t match)');
          }
        }
      } catch (e) {
        _logger.fine('Could not check NIP55 (maybe not installed or not NIP55 account): $e');
      }

      _logger.info('Calling deleteAccountKeyPackage: pubkey=$activePubkey, id=$keyPackageId');

      final bool deleted = await accounts_api.deleteAccountKeyPackage(
        accountPubkey: activePubkey,
        keyPackageId: keyPackageId,
      );

      _logger.info('Delete result: $deleted');

      if (!deleted) {
        _logger.warning('Delete returned false');
        ref.showWarningToast('settings.failedToDeleteKeyPackage'.tr());
        return;
      }

      _logger.info('Delete successful');
      ref.showSuccessToast('settings.keyPackageDeletedSuccess'.tr());

      await _fetchKeyPackages(showLoading: false);
    } catch (e, st) {
      _logger.severe('Delete key package exception', e, st);

      final message = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage: 'settings.failedToDeleteKeyPackage'.tr(),
        context: 'deleteKeyPackage',
      );
      ref.showErrorToast(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WnSettingsScreenWrapper(
      safeAreaBottom: false,
      title: 'settings.developerSettings'.tr(),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Gap(24.h),
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
                            onPressed: _isAnyOperationInProgress ? null : _publishKeyPackage,
                            loading: _isPublishingKeyPackage,
                          ),
                          Gap(8.h),
                          WnFilledButton(
                            label: 'settings.inspectRelayKeyPackages'.tr(),
                            onPressed: _isAnyOperationInProgress ? null : _fetchKeyPackages,
                            loading: _isFetchingKeyPackages,
                          ),
                          Gap(8.h),
                          WnFilledButton(
                            label: 'settings.deleteAllKeyPackagesFromRelays'.tr(),
                            visualState: WnButtonVisualState.destructive,
                            onPressed: _isAnyOperationInProgress ? null : _deleteAllKeyPackages,
                            loading: _isDeletingAllKeyPackages,
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
                    Gap(MediaQuery.viewPaddingOf(context).bottom + 24.h),
                  ],
                ),
              ),
            ),
          ),
        ],
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
