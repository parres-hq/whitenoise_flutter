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
      body: Stack(
        children: [
          SafeArea(
            top: true,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
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
                      borderRadius: BorderRadius.circular(16),
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
                                borderRadius: BorderRadius.circular(24),
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 96,
              color: AppColors.black,
              padding: const EdgeInsets.only(top: 20),
              child: TextButton(
                style: ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(AppColors.transparent),
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                ),
                onPressed: () => _onContinuePressed(context),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    'Continue',
                    style: TextStyle(fontSize: 18, color: AppColors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
