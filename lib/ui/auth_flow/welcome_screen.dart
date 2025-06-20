import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
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

    await authNotifier.initialize();
    await authNotifier.createAccount();

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.error == null) {
      if (!context.mounted) return;
      context.go('/onboarding');
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authState.error ?? 'Unknown error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.colors.neutral,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                ),
                child: SizedBox(
                  height: 360.h,
                  width: double.infinity,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      AssetsPaths.loginSplash,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    Text(
                      'Welcome to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Overused Grotesk',
                        fontWeight: FontWeight.w400,
                        fontSize: 36.sp,
                        height: 1.0,
                        letterSpacing: -0.72,
                        color: context.colors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'White Noise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Overused Grotesk',
                        fontWeight: FontWeight.w600,
                        fontSize: 51.sp,
                        height: 1.0,
                        letterSpacing: -1.02,
                        color: context.colors.primary,
                      ),
                    ),
                    Text(
                      'Secure. Distributed. Uncensorable.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                        height: 1.0,
                        letterSpacing: 0,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
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
                  Gap(16.h),
                  authState.isLoading
                      ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.black),
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
