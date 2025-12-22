import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/nostr_keys_provider.dart';
import 'package:whitenoise/config/states/nostr_keys_state.dart';
import 'package:whitenoise/domain/services/nip55_service.dart';
import 'package:whitenoise/src/rust/api/nip55.dart' as nip55_api;
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_icon_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/ui/core/widgets/wn_settings_screen_wrapper.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ProfileKeysScreen extends ConsumerStatefulWidget {
  const ProfileKeysScreen({super.key});

  @override
  ConsumerState<ProfileKeysScreen> createState() => _ProfileKeysScreenState();
}

class _ProfileKeysScreenState extends ConsumerState<ProfileKeysScreen> {
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  bool _obscurePrivateKey = true;
  bool _isExternalSignerEnabled = false;
  bool _isCheckingSigner = false;
  bool _isSignerInstalled = false;
  ProviderSubscription<NostrKeysState>? _nostrKeysSubscription;
  static final Logger _logger = Logger('ProfileKeysScreen');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(nostrKeysProvider.notifier).loadKeys();

      // Check if external signer is installed (Android only)
      if (Platform.isAndroid) {
        await _checkExternalSignerInstalled();
        await _checkExternalSignerEnabled();
      }
    });

    // Listen to key changes and update controllers
    _nostrKeysSubscription = ref.listenManual(nostrKeysProvider, (previous, next) {
      _updateKeyControllers();
    });
  }

  Future<void> _updateKeyControllers() async {
    if (!mounted) return;

    // Get the active account's pubkey directly
    try {
      final activeAccount = await ref.read(activeAccountProvider.future);
      if (activeAccount.account != null) {
        final accountPubkey = activeAccount.account!.pubkey;
        // Convert hex pubkey to npub format
        final npub = PubkeyFormatter(pubkey: accountPubkey).toNpub() ?? accountPubkey;
        final newPublicKey = npub.formatPublicKey();

        if (_publicKeyController.text != newPublicKey && mounted) {
          _publicKeyController.text = newPublicKey;
        }
      }
    } catch (e) {
      _logger.warning('Error updating public key controller: $e');
      // Fallback to nostrKeys if available
      if (mounted) {
        final nostrKeys = ref.read(nostrKeysProvider);
        final newPublicKey = nostrKeys.npub?.formatPublicKey() ?? '';
        if (_publicKeyController.text != newPublicKey) {
          _publicKeyController.text = newPublicKey;
        }
      }
    }

    // Update private key from nostrKeys
    if (mounted) {
      final nostrKeys = ref.read(nostrKeysProvider);
      final newPrivateKey = nostrKeys.nsec ?? '';
      if (_privateKeyController.text != newPrivateKey) {
        _privateKeyController.text = newPrivateKey;
      }
    }
  }

  Future<void> _checkExternalSignerInstalled() async {
    setState(() {
      _isCheckingSigner = true;
    });

    try {
      final installed = await Nip55Service.isExternalSignerInstalled();
      if (mounted) {
        setState(() {
          _isSignerInstalled = installed;
          _isCheckingSigner = false;
        });
      }
    } catch (e) {
      _logger.warning('Error checking external signer: $e');
      if (mounted) {
        setState(() {
          _isCheckingSigner = false;
        });
      }
    }
  }

  /// Check if NIP-55 signer is enabled for the current account
  /// by checking if the account has a private key (nsec)
  /// If there's no private key, the account is using NIP-55 external signer
  Future<void> _checkExternalSignerEnabled() async {
    if (!_isSignerInstalled) {
      return;
    }

    try {
      final nostrKeys = ref.read(nostrKeysProvider);

      // If the account doesn't have a private key (nsec), it's using NIP-55 external signer
      // No need to call the signer app - we already know from the account state
      if (nostrKeys.nsec == null || nostrKeys.nsec!.isEmpty) {
        _logger.fine('Account has no private key, using NIP-55 external signer');
        if (mounted) {
          setState(() {
            _isExternalSignerEnabled = true;
          });
        }
      } else {
        _logger.fine('Account has private key, not using NIP-55 external signer');
        if (mounted) {
          setState(() {
            _isExternalSignerEnabled = false;
          });
        }
      }
    } catch (e, stackTrace) {
      _logger.fine('Could not check NIP-55 signer enabled state: $e', e, stackTrace);
    }
  }

  Future<void> _toggleExternalSigner(bool enabled) async {
    final activeAccount = await ref.read(activeAccountProvider.future);
    if (activeAccount.account == null) {
      ref.showErrorToast('No active account');
      return;
    }

    final pubkey = activeAccount.account!.pubkey;

    setState(() {
      _isExternalSignerEnabled = enabled;
    });

    try {
      if (enabled) {
        // Check if signer is installed before enabling
        if (!_isSignerInstalled) {
          final installed = await Nip55Service.isExternalSignerInstalled();
          if (!installed) {
            setState(() {
              _isExternalSignerEnabled = false;
            });
            ref.showErrorToast('External signer app not installed');
            return;
          }
          setState(() {
            _isSignerInstalled = true;
          });
        }

        await nip55_api.enableNip55Signer(pubkey: pubkey);
        ref.showSuccessToast('External signer enabled');
        // Reload keys to update the state (nsec will be null for NIP-55 accounts)
        await ref.read(nostrKeysProvider.notifier).loadKeys();
      } else {
        await nip55_api.disableNip55Signer(pubkey: pubkey);
        ref.showSuccessToast('External signer disabled');
      }
    } catch (e) {
      _logger.severe('Error toggling external signer: $e');
      setState(() {
        _isExternalSignerEnabled = !enabled;
      });
      ref.showErrorToast('Failed to ${enabled ? 'enable' : 'disable'} external signer: $e');
    }
  }

  void _copyPublicKey() async {
    try {
      // Get the active account's pubkey directly
      final activeAccount = await ref.read(activeAccountProvider.future);
      if (activeAccount.account != null) {
        final accountPubkey = activeAccount.account!.pubkey;
        // Convert hex pubkey to npub format
        final npub = PubkeyFormatter(pubkey: accountPubkey).toNpub() ?? accountPubkey;
        ClipboardUtils.copyWithToast(
          ref: ref,
          textToCopy: npub,
          successMessage: 'nostrKeys.copyPublicKeySuccess'.tr(),
        );
        return;
      }
    } catch (e) {
      _logger.warning('Error copying public key: $e');
    }

    // Fallback to nostrKeys if available
    final npub = ref.read(nostrKeysProvider).npub;
    if (npub != null && npub.isNotEmpty) {
      ClipboardUtils.copyWithToast(
        ref: ref,
        textToCopy: npub,
        successMessage: 'nostrKeys.copyPublicKeySuccess'.tr(),
      );
    }
  }

  void _copyPrivateKey() async {
    final nsec = ref.read(nostrKeysProvider).nsec;
    if (nsec != null) {
      await ClipboardUtils.copySensitiveWithToast(
        ref: ref,
        textToCopy: nsec,
        successMessage: 'nostrKeys.copyPrivateKeySuccess'.tr(),
      );
    }
  }

  void _togglePrivateKeyVisibility() {
    setState(() {
      _obscurePrivateKey = !_obscurePrivateKey;
    });
  }

  @override
  void dispose() {
    _nostrKeysSubscription?.close();
    _privateKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nostrKeys = ref.watch(nostrKeysProvider);

    return WnSettingsScreenWrapper(
      title: 'settings.profileKeys'.tr(),
      safeAreaBottom: false,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'nostrKeys.publicKeyTitle'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colors.primary,
                        ),
                      ),
                      Gap(10.h),
                      Row(
                        children: [
                          Expanded(
                            child: WnTextFormField(
                              controller: _publicKeyController,
                              readOnly: true,
                              size: FieldSize.small,
                            ),
                          ),
                          Gap(4.w),
                          WnIconButton(
                            onTap: _copyPublicKey,
                            iconPath: AssetsPaths.icCopy,
                            size: 44.h,
                            padding: 14.w,
                          ),
                        ],
                      ),
                      Gap(12.h),
                      Text(
                        'nostrKeys.publicKeyDescription'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: context.colors.mutedForeground,
                        ),
                      ),
                      Gap(36.h),
                      // Hide private key section when using external signer
                      if (!_isExternalSignerEnabled) ...[
                        Text(
                          'nostrKeys.privateKeyTitle'.tr(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                        Gap(10.h),
                        if (nostrKeys.isLoading)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.colors.mutedForeground,
                                  ),
                                ),
                              ),
                              Gap(12.w),
                              Text(
                                'nostrKeys.loadingPrivateKey'.tr(),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: context.colors.mutedForeground,
                                ),
                              ),
                            ],
                          )
                        else if (nostrKeys.error != null)
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                WnImage(
                                  AssetsPaths.icErrorFilled,
                                  color: context.colors.destructive,

                                  size: 20.w,
                                ),
                                Gap(12.w),
                                Expanded(
                                  child: Text(
                                    '${'nostrKeys.errorLoadingPrivateKey'.tr()}: ${nostrKeys.error}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: context.colors.destructive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: WnTextFormField(
                                  controller: _privateKeyController,
                                  readOnly: true,
                                  obscureText: _obscurePrivateKey,
                                  size: FieldSize.small,
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      onPressed: _togglePrivateKeyVisibility,
                                      icon: WnImage(
                                        _obscurePrivateKey
                                            ? AssetsPaths.icEye
                                            : AssetsPaths.icEyeOff,
                                        size: _obscurePrivateKey ? 16.w : 19.w,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Gap(4.w),
                              WnIconButton(
                                onTap: _copyPrivateKey,
                                iconPath: AssetsPaths.icCopy,
                                size: 44.h,
                                padding: 14.w,
                              ),
                            ],
                          ),
                        Gap(10.h),
                        Text(
                          'nostrKeys.privateKeyDescription'.tr(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.mutedForeground,
                          ),
                        ),
                        Gap(36.h),
                      ],
                      if (Platform.isAndroid) ...[
                        Text(
                          'nostrKeys.externalSignerTitle'.tr(),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                        Gap(10.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: context.colors.avatarSurface,
                            border: Border.all(
                              color: context.colors.border,
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isExternalSignerEnabled
                                          ? 'nostrKeys.usingExternalSigner'.tr()
                                          : 'nostrKeys.useExternalSigner'.tr(),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                    Gap(4.h),
                                    if (_isCheckingSigner)
                                      Text(
                                        'nostrKeys.checkingSigner'.tr(),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: context.colors.mutedForeground,
                                        ),
                                      )
                                    else if (!_isSignerInstalled)
                                      Text(
                                        'nostrKeys.signerNotInstalled'.tr(),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: context.colors.destructive,
                                        ),
                                      )
                                    else if (_isExternalSignerEnabled)
                                      Text(
                                        'nostrKeys.externalSignerEnabledDescription'.tr(),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: context.colors.mutedForeground,
                                        ),
                                      )
                                    else
                                      Text(
                                        'nostrKeys.externalSignerDescription'.tr(),
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: context.colors.mutedForeground,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Gap(12.w),
                              if (_isExternalSignerEnabled)
                                Icon(
                                  Icons.check_circle,
                                  color: context.colors.primary,
                                  size: 24.w,
                                )
                              else
                                Switch(
                                  value: _isExternalSignerEnabled,
                                  onChanged: _isSignerInstalled ? _toggleExternalSigner : null,
                                  activeThumbColor: context.colors.primary,
                                ),
                            ],
                          ),
                        ),
                        Gap(24.h),
                      ],
                      // Hide warning box when using external signer
                      if (!_isExternalSignerEnabled)
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: context.colors.destructive.withValues(alpha: 0.1),
                            border: Border.all(
                              color: context.colors.destructive,
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 4.w),
                                child: WnImage(
                                  AssetsPaths.icWarning,
                                  size: 16.w,
                                  color: context.colors.destructive,
                                ),
                              ),
                              Gap(12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'nostrKeys.privateKeyWarningTitle'.tr(),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                    Gap(8.h),
                                    Text(
                                      'nostrKeys.privateKeyWarningDescription'.tr(),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: context.colors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Gap(24.h),
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
