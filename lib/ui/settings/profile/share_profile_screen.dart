import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/nostr_keys_provider.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';
import 'package:whitenoise/utils/string_extensions.dart';

class ShareProfileScreen extends ConsumerStatefulWidget {
  const ShareProfileScreen({super.key});

  @override
  ConsumerState<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends ConsumerState<ShareProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load profile and keys when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchProfileData();
      ref.read(nostrKeysProvider.notifier).loadPublicKey();
    });
  }

  void _copyPublicKey() {
    final npub = ref.read(nostrKeysProvider).npub;
    if (npub != null) {
      Clipboard.setData(ClipboardData(text: npub));
      ref.showRawSuccessToast('Public key copied to clipboard');
    } else {
      ref.showRawErrorToast('Public key not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final keysState = ref.watch(nostrKeysProvider);

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
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Gap(24.h),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: SvgPicture.asset(
                          AssetsPaths.icChevronLeft,
                          width: 24.w,
                          height: 24.w,
                          colorFilter: ColorFilter.mode(
                            context.colors.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      Gap(16.w),
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
                  Gap(40.h),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 96.w,
                          height: 96.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.input,
                          ),
                          child: profileState.when(
                            data:
                                (profile) => ClipOval(
                                  child:
                                      (profile.picture ?? '').isNotEmpty
                                          ? Image.network(
                                            profile.picture!,
                                            fit: BoxFit.cover,
                                            width: 96.w,
                                            height: 96.w,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _buildFallbackAvatar(
                                                      profile.displayName ?? 'U',
                                                    ),
                                          )
                                          : _buildFallbackAvatar(profile.displayName ?? 'U'),
                                ),
                            loading: () => _buildFallbackAvatar('...'),
                            error: (error, stackTrace) => _buildFallbackAvatar('?'),
                          ),
                        ),
                        Gap(8.h),
                        profileState.when(
                          data:
                              (profile) => Text(
                                profile.displayName ?? 'Unknown User',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                          loading:
                              () => Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.mutedForeground,
                                ),
                              ),
                          error:
                              (error, stackTrace) => Text(
                                'Error loading profile',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.destructive,
                                ),
                              ),
                        ),
                        profileState.when(
                          data: (profile) {
                            if (profile.nip05 == null || profile.nip05!.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              profile.nip05 ?? 'No NIP-05 address',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: context.colors.mutedForeground,
                              ),
                            );
                          },
                          loading:
                              () => Text(
                                'Loading...',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: context.colors.mutedForeground,
                                ),
                              ),
                          error: (error, stackTrace) => const SizedBox.shrink(),
                        ),
                        Gap(16.h),
                        keysState.npub != null
                            ? Text(
                              keysState.npub!.formatPublicKey(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: context.colors.mutedForeground,
                              ),
                              textAlign: TextAlign.center,
                            )
                            : Text(
                              'Loading public key...',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: context.colors.mutedForeground,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        Gap(16.h),
                        AppFilledButton.child(
                          onPressed: keysState.npub != null ? _copyPublicKey : null,
                          visualState: AppButtonVisualState.secondary,
                          size: AppButtonSize.small,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Copy Public Key',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.primary,
                                ),
                              ),
                              Gap(9.w),
                              Icon(
                                CarbonIcons.copy,
                                color: context.colors.primary,
                                size: 16.w,
                              ),
                            ],
                          ),
                        ),
                        Gap(52.h),
                        if (keysState.npub != null) ...[
                          QrImageView(
                            data: keysState.npub!,
                            size: 248.w, // 280 - 32 (padding)
                            eyeStyle: QrEyeStyle(
                              color: context.colors.primary,
                              eyeShape: QrEyeShape.square,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              color: context.colors.primary,
                              dataModuleShape: QrDataModuleShape.square,
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: 280.w,
                            height: 280.w,
                            decoration: BoxDecoration(
                              color: context.colors.input,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: context.colors.border),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: context.colors.mutedForeground,
                                  ),
                                  Gap(16.h),
                                  Text(
                                    'Loading QR code...',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: context.colors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        Gap(16.h),
                        Text(
                          'Scan to connect.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: context.colors.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Gap(32.h),
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

  Widget _buildFallbackAvatar(String displayName) {
    return Container(
      width: 120.w,
      height: 120.w,
      color: context.colors.input,
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: context.colors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
