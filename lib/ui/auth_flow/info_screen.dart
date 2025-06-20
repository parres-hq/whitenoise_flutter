import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/ui/core/ui/app_button.dart';

import '../core/themes/assets.dart';
import '../core/themes/src/extensions.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  void _onContinuePressed(BuildContext context) {
    context.go('/onboarding/create-profile');
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 36),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imagePath,
            width: 130,
            height: 130,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colors.mutedForeground,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(
            children: [
              Text(
                'Security Without\nCompromise',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                  color: context.colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 32),
              _buildFeatureItem(
                context,
                imagePath: AssetsPaths.blueHoodie,
                title: 'Privacy & Security',
                subtitle:
                    'Keep your conversations private. Even in case of a breach, your messages remain secure.',
              ),
              _buildFeatureItem(
                context,
                imagePath: AssetsPaths.purpleWoman,
                title: 'Identity–Free',
                subtitle:
                    'Chat without revealing your phone number or email. Choose your identity: real name, pseudonym, or anonymous.',
              ),
              _buildFeatureItem(
                context,
                imagePath: AssetsPaths.greenBird,
                title: 'Decentralized & Permissionless',
                subtitle:
                    'No central authority controls your communication—no permissions needed, no censorship possible.',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
          ).copyWith(bottom: 32.h),
          child: AppFilledButton(
            onPressed: () => _onContinuePressed(context),
            title: 'Setup Your Profile',
          ),
        ),
      ),
    );
  }
}
