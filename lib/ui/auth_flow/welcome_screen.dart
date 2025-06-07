import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';
import 'package:whitenoise/ui/core/ui/custom_text_button.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Future<void> _handleCreateAccount(BuildContext context) async {
    final auth = ref.read(authProvider);

    await auth.initialize();
    await auth.createAccount();

    if (auth.isAuthenticated && auth.error == null) {
      if (!mounted) return;
      context.go('/onboarding/key-created');
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
              Expanded(
                flex: 5,
                child: SizedBox(
                  width: double.infinity,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.transparent],
                        stops: [0.7, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(AssetsPaths.loginSplash, fit: BoxFit.cover),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Welcome to',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, color: Colors.black, height: 1.1),
                      ),
                      Text(
                        'White Noise',
                        style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, color: Colors.black, height: 1.1),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Secure. Distributed. Uncensorable.',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextButton(
                  onPressed: () => GoRouter.of(context).go('/login'),
                  title: 'Sign In',
                ),
                Gap(16.w),
                CustomFilledButton(
                  onPressed: auth.isLoading ? null : () => _handleCreateAccount(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Create Account', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
                      Gap(8.w),
                      Icon(Icons.arrow_forward, size: 16.sp),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (auth.isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.black),
            ),
          ),
      ],
    );
  }
}
