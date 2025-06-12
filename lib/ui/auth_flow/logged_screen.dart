import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';

class LoggedInScreen extends StatelessWidget {
  const LoggedInScreen({super.key});

  void _onContinuePressed(BuildContext context) {
    context.go(Routes.contacts);
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Text(
                        "You're signed in",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        "Let's see if you already have previous activity.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.glitch400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Looking for your contacts',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Looking for chats',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: CustomFilledButton(onPressed: () => _onContinuePressed(context), title: 'Continue'),
      ),
    );
  }
}
