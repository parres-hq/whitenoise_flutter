import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:go_router/go_router.dart';

class KeyCreatedScreen extends StatelessWidget {
  const KeyCreatedScreen({super.key});

  void _onContinuePressed(BuildContext context) {
    GoRouter.of(context).go('/onboarding/logged-in');
  }

  void _onCopyPressed(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied!')));
  }

  @override
  Widget build(BuildContext context) {
    const dummyKey = '''
blah blah blah blah blah blah
blah blah blah blah blah blah
blah blah blah blah blah blah
blah blah blah blah blah blah
''';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'We created a\nprivate key for you',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Store this in a secure location. It\'s your main\npassword to this profile and your messages.',
                      style: TextStyle(fontSize: 16, color: AppColors.glitch400),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.glitch100,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            dummyKey.trim(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, height: 1.5),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.black,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              onPressed: () => _onCopyPressed(context),
                              child: const Text('Copy'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'You can skip now and we\'ll remind\nyou to do this later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.glitch400),
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
