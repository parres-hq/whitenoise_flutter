import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';

import '../core/themes/assets.dart';
import '../core/themes/src/extensions.dart';

class InfoScreen extends ConsumerStatefulWidget {
  const InfoScreen({super.key});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> {
  bool _isLoading = false;

  Future<void> _onContinuePressed(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    // Wait a bit for any background processes to complete
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    setState(() {
      _isLoading = false;
    });

    context.go('/onboarding/create-profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 0).w,
            child: Column(
              children: [
                Text(
                  'Security Without\nCompromise',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                    color: context.colors.mutedForeground,
                  ),
                ),
                Gap(48.h),
                FeatureItem(
                  context: context,
                  imagePath: AssetsPaths.blueHoodie,
                  title: 'Privacy & Security',
                  subtitle:
                      'Keep your conversations private. Even in case of a breach, your messages remain secure.',
                ),
                FeatureItem(
                  context: context,
                  imagePath: AssetsPaths.purpleWoman,
                  title: 'Choose Identity',
                  subtitle:
                      'Chat without revealing your phone number or email. Choose your identity: real name, pseudonym, or anonymous.',
                ),
                FeatureItem(
                  context: context,
                  imagePath: AssetsPaths.greenBird,
                  title: 'Decentralized & Permissionless',
                  subtitle:
                      'No central authority controls your communication—no permissions needed, no censorship possible.',
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
          ).copyWith(bottom: 32.h),
          child:
              _isLoading
                  ? SizedBox(
                    height: 56.h,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.colors.primaryForeground,
                      ),
                    ),
                  )
                  : AppFilledButton.child(
                    onPressed: () => _onContinuePressed(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Setup Profile',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primaryForeground,
                          ),
                        ),
                        Gap(14.w),
                        SvgPicture.asset(
                          AssetsPaths.icArrowRight,
                          colorFilter: ColorFilter.mode(
                            context.colors.primaryForeground,
                            BlendMode.srcIn,
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

class FeatureItem extends StatelessWidget {
  const FeatureItem({
    super.key,
    required this.context,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  final BuildContext context;
  final String imagePath;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36).w,
      child: Row(
        children: [
          Image.asset(imagePath, width: 128.w, height: 128.w, fit: BoxFit.contain),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: context.colors.primary,
                  ),
                ),
                Gap(6.w),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6.w,
                    color: context.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
