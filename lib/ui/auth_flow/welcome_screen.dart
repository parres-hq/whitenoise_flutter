import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
import 'package:whitenoise/ui/core/ui/custom_text_button.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Future<void> _handleCreateAccount() async {
    final auth = ref.read(authProvider);
    await auth.initialize();

    await auth.createAccount();

    if (!mounted) return;

    if (auth.isAuthenticated && auth.error == null) {
      context.go('/onboarding');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Unknown error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
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
                child: const Column(
                  children: [
                    Text(
                      'Welcome to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Overused Grotesk',
                        fontWeight: FontWeight.w400,
                        fontSize: 34,
                        height: 1.0,
                        letterSpacing: -0.72,
                        color: AppColors.glitch600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'White Noise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Overused Grotesk',
                        fontWeight: FontWeight.w600,
                        fontSize: 50,
                        height: 1.0,
                        letterSpacing: -1.02,
                        color: AppColors.glitch950,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Secure. Distributed. Uncensorable.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.0,
                        letterSpacing: 0,
                        color: AppColors.glitch950,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextButton(
                  onPressed: () => context.go('/login'),
                  title: 'Login',
                ),
                Gap(16.h),

                auth.isLoading
                    ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      ),
                    )
                    : CustomFilledButton(
                      onPressed: _handleCreateAccount,
                      title: 'Sign Up',
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
