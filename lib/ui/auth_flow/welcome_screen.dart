import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Future<void> _handleCreateAccount(BuildContext context) async {
    final authNotifier = ref.read(authProvider.notifier);

    await authNotifier.createAccount();

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.error == null) {
      if (!context.mounted) return;
      context.go('/onboarding');
    } else {
      if (!context.mounted) return;
      ref.showErrorToast(authState.error ?? 'Unknown error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Stack(
      children: [
        Scaffold(
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
                      SvgPicture.asset(
                        AssetsPaths.icWhiteNoiseSvg,
                        width: 170.w,
                        height: 130.h,
                        colorFilter: ColorFilter.mode(
                          context.colors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      Gap(24.h),
                      Text(
                        'White Noise',
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
                        'Decentralized. Uncensorable.\nSecure Messaging. ',
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
            child: Padding(
              padding: EdgeInsets.only(bottom: 32.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFilledButton(
                    title: 'Login',
                    visualState: AppButtonVisualState.secondary,
                    onPressed: () => context.go('/login'),
                  ),
                  Gap(4.h),
                  authState.isLoading
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(color: context.colors.primary),
                        ),
                      )
                      : AppFilledButton(
                        title: 'Sign Up',
                        onPressed: () => _handleCreateAccount(context),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
