import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/config/providers/toast_message_provider.dart';
import 'package:whitenoise/config/states/toast_state.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
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
      await ref.read(profileProvider.notifier).fetchProfileData();
      npub = await ref.read(activeAccountProvider)?.toNpub() ?? '';
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ref.showErrorToast('Failed to load profile: ${e.toString()}');
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ref
        .read(toastMessageProvider.notifier)
        .showRawToast(
          message: 'Copied to clipboard',
          type: ToastType.success,
        );
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(profileProvider);

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
                      'Share Profile',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                currentProfile.when(
                  data: (profile) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        children: [
                          Gap(16.h),
                          ContactAvatar(
                            imageUrl: profile.picture ?? '',
                            displayName: profile.displayName ?? '',
                            size: 96.w,
                            showBorder: true,
                          ),
                          Gap(8.h),
                          Text(
                            profile.displayName ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                          if (profile.nip05 != null) ...[
                            Text(
                              profile.nip05!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: context.colors.mutedForeground,
                              ),
                            ),
                          ],
                          Gap(18.h),
                          Text(
                            npub.formatPublicKey(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: context.colors.mutedForeground,
                            ),
                          ),
                          Gap(16.h),
                          AppFilledButton.icon(
                            visualState: AppButtonVisualState.secondary,
                            label: SvgPicture.asset(
                              AssetsPaths.icCopy,
                              colorFilter: ColorFilter.mode(
                                context.colors.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                            icon: Text(
                              'Copy Public Key',
                              style: TextStyle(
                                color: context.colors.primary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () => _copyToClipboard(context, npub),
                          ),
                          Gap(32.h),
                          QrImageView(
                            data: npub,
                            size: 256.w,
                            gapless: false,
                          ),
                          Gap(10.h),
                          Text(
                            'Scan to connect.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: context.colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stackTrace) => const Center(
                        child: Text('Error loading profile'),
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
