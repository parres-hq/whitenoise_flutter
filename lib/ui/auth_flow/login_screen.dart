import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _keyController = TextEditingController();

  void _onContinuePressed() {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter something')));
      return;
    }
    ref.read(authProvider).login();
    // go_router will handle redirect to contacts
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
                        'Sign in',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'White Noise requires a ',
                          style: TextStyle(fontSize: 16, color: AppColors.black),
                          children: [
                            TextSpan(
                              text: 'Nostr private key',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: AppColors.black,
                              ),
                            ),
                            TextSpan(text: ' to use.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Enter your Nostr private key',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _keyController,
                      decoration: InputDecoration(
                        hintText: 'nsec...',
                        filled: true,
                        fillColor: AppColors.glitch100,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'Your key will be encrypted and only\nstored on your device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.glitch400),
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
            onPressed: _onContinuePressed,
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
