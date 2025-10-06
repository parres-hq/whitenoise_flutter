import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_button.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isCreatingAccount = false;

  Future<void> _handleCreateAccount(BuildContext context) async {
    setState(() {
      _isCreatingAccount = true;
    });

    final authNotifier = ref.read(authProvider.notifier);

    // Start account creation in background without loading state
    authNotifier.createAccountInBackground();

    // Navigate immediately to onboarding
    if (!context.mounted) return;
    context.go('/onboarding');
    if (!mounted) return;
    setState(() {
      _isCreatingAccount = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);

    return Scaffold(
      backgroundColor: context.colors.neutral,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  WnImage(
                    AssetsPaths.icWhiteNoiseSvg,
                    width: 170.w,
                    height: 130.h,
                    color: context.colors.primary,
                  ),
                  Gap(24.h),
                  Text(
                    'auth.whiteNoise'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 48.sp,
                      letterSpacing: -0.6.sp,
                      color: context.colors.primary,
                    ),
                  ),
                  Gap(6.h),
                  Text(
                    'auth.slogan'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 18.sp,
                      letterSpacing: 0.1.sp,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: 54.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WnFilledButton(
                label: 'auth.login'.tr(),
                visualState: WnButtonVisualState.secondary,
                onPressed: _isCreatingAccount ? null : () => context.go('/login'),
              ),
              Gap(8.h),
              WnFilledButton(
                label: 'auth.signup'.tr(),
                loading: _isCreatingAccount,
                onPressed: _isCreatingAccount ? null : () => _handleCreateAccount(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
