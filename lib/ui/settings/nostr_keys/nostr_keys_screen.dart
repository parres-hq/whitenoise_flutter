import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';

import 'package:whitenoise/config/providers/nostr_keys_provider.dart';
import 'package:whitenoise/shared/custom_icon_button.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';

class NostrKeysScreen extends ConsumerStatefulWidget {
  const NostrKeysScreen({super.key});

  @override
  ConsumerState<NostrKeysScreen> createState() => _NostrKeysScreenState();
}

class _NostrKeysScreenState extends ConsumerState<NostrKeysScreen> {
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  bool _obscurePrivateKey = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(nostrKeysProvider.notifier).loadKeys();
      _publicKeyController.text = ref.read(nostrKeysProvider).npub ?? '';
      _privateKeyController.text = ref.read(nostrKeysProvider).nsec ?? '';
    });
  }

  void _copyPublicKey() {
    final npub = ref.read(nostrKeysProvider).npub;
    ClipboardUtils.copyWithToast(
      ref: ref,
      textToCopy: npub,
      successMessage: 'Public key copied to clipboard',
    );
  }

  void _copyPrivateKey() {
    final nsec = ref.read(nostrKeysProvider).nsec;
    if (nsec != null) {
      ClipboardUtils.copyWithToast(
        ref: ref,
        textToCopy: nsec,
        successMessage: 'Private key copied to clipboard',
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
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
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
                            'Profile Keys',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Gap(29.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Public Key',
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
                                ),
                              ),
                              Gap(8.w),
                              CustomIconButton(
                                onTap: _copyPublicKey,
                                iconPath: AssetsPaths.icCopy,
                                size: 56.h,
                                padding: 20.w,
                              ),
                            ],
                          ),
                          Gap(12.h),
                          Text(
                            'Your public key is your unique identifier in the Nostr network, enabling others to verify and recognize your messages. Share it openly!',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.mutedForeground,
                            ),
                          ),
                          Gap(36.h),
                          Text(
                            'Private Key',
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
                                  'Loading private key...',
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
                                  Icon(
                                    Icons.error,
                                    color: context.colors.destructive,
                                    size: 20.r,
                                  ),
                                  Gap(12.w),
                                  Expanded(
                                    child: Text(
                                      'Error loading private key: ${nostrKeys.error}',
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
                                    decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        onPressed: _togglePrivateKeyVisibility,
                                        icon: Icon(
                                          _obscurePrivateKey
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: context.colors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Gap(8.w),
                                CustomIconButton(
                                  onTap: _copyPrivateKey,
                                  iconPath: AssetsPaths.icCopy,
                                  size: 56.h,
                                  padding: 20.w,
                                ),
                              ],
                            ),
                          Gap(10.h),
                          Text(
                            'Private key works like a secret password that grants access to your Nostr identity.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.mutedForeground,
                            ),
                          ),
                          Gap(12.h),
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
                                  child: Icon(
                                    Icons.warning,
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
                                        'Keep your private key safe!',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.primary,
                                        ),
                                      ),
                                      Gap(8.h),
                                      Text(
                                        'Don\'t share your private key publicly, and use it only to log in to other Nostr apps.',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
