import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  void _onContinuePressed(BuildContext context) {
    context.go('/onboarding/create-profile');
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: CircleAvatar(backgroundColor: AppColors.black, radius: 12),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 15, color: AppColors.glitch400),
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "What's unique\nabout White Noise",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildFeatureItem(
                      'Private by default',
                      'No one can trace who you talk to.',
                    ),
                    _buildFeatureItem(
                      'Cannot be censored',
                      'Even the people who made this application cannot restrict you.',
                    ),
                    _buildFeatureItem(
                      'Super secure',
                      'Only you are in control of your data.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () => _onContinuePressed(context),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
