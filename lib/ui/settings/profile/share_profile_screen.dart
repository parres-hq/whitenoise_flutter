import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/clipboard_utils.dart';
import 'package:whitenoise/utils/localization_extensions.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ShareProfileScreen extends ConsumerStatefulWidget {
  const ShareProfileScreen({super.key});

  @override
  ConsumerState<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends ConsumerState<ShareProfileScreen> {
  String npub = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadProfile();
    });
  }

  Future<void> loadProfile() async {
    try {
      final activeAccountPubkey = ref.read(activePubkeyProvider) ?? '';
      npub = PubkeyFormatter(pubkey: activeAccountPubkey).toNpub() ?? '';
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ref.showErrorToast('${'profile.failedToLoadProfile'.tr()}: ${e.toString()}');
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    ClipboardUtils.copyWithToast(
      ref: ref,
      textToCopy: text,
      successMessage: 'profile.publicKeyCopied'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeAccountState = ref.watch(activeAccountProvider);

    return AnnotatedRegion(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Gap(24.h),
                Row(
                  children: [
                    const BackButton(),
                    Text(
                      'profile.shareProfile'.tr(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: activeAccountState.when(
                    data: (state) {
                      final profile = state.metadata;
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          children: [
                            Gap(16.h),
                            WnAvatar(
                              imageUrl: profile?.picture ?? '',
                              displayName: profile?.displayName ?? '',
                              size: 96.w,
                              showBorder: true,
                              pubkey: state.account?.pubkey,
                            ),
                            Gap(8.h),
                            Text(
                              profile?.displayName ?? '',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primary,
                              ),
                            ),
                            if (profile?.nip05 != null) ...[
                              Text(
                                profile?.nip05 ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.mutedForeground,
                                ),
                              ),
                            ],
                            Gap(18.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      npub.formatPublicKey(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: context.colors.mutedForeground,
                                      ),
                                    ),
                                  ),
                                  Gap(8.w),
                                  InkWell(
                                    onTap: () => _copyToClipboard(context, npub),
                                    child: WnImage(
                                      AssetsPaths.icCopy,
                                      size: 24.w,
                                      color: context.colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Gap(32.h),
                            QrImageView(
                              data: npub,
                              size: 256.w,
                              gapless: false,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: context.colors.solidNeutralBlack,
                              ),
                              backgroundColor: context.colors.solidNeutralWhite,
                            ),
                            Gap(10.h),
                            Text(
                              'profile.scanToConnect'.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: context.colors.mutedForeground,
                              ),
                            ),
                            const Spacer(),
                            WnFilledButton(
                              label: 'profile.scanQrCode'.tr(),
                              suffixIcon: WnImage(
                                AssetsPaths.icScan,
                                size: 18.w,
                                color: context.colors.primaryForeground,
                              ),
                              onPressed: () => context.push(Routes.settingsShareProfileQrScan),
                            ),
                            Gap(64.h),
                          ],
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error:
                        (error, stackTrace) => Center(
                          child: Text('ui.errorLoadingProfile'.tr()),
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
