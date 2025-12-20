import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/nostr_keys_provider.dart';
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
  static final Logger _logger = Logger('ProfileKeysScreen');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(nostrKeysProvider.notifier).loadKeys();
      _publicKeyController.text = ref.read(nostrKeysProvider).npub?.formatPublicKey() ?? '';
      _privateKeyController.text = ref.read(nostrKeysProvider).nsec ?? '';

      // Check if external signer is installed (Android only)
      if (Platform.isAndroid) {
        _checkExternalSignerInstalled();
      }
    });
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

  void _copyPublicKey() {
    final npub = ref.read(nostrKeysProvider).npub;
    ClipboardUtils.copyWithToast(
      ref: ref,
      textToCopy: npub,
      successMessage: 'nostrKeys.copyPublicKeySuccess'.tr(),
    );
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
                                      _obscurePrivateKey ? AssetsPaths.icEye : AssetsPaths.icEyeOff,
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
                                      'nostrKeys.useExternalSigner'.tr(),
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
