import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your private key')),
      );
      return;
    }

    if (mounted) {
      context.go(Routes.chats);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      _keyController.text = clipboardData.text!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pasted from clipboard')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to paste from clipboard')),
        );
      }
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Image.asset(
                    AssetsPaths.hands,
                    height: 320,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Login to White Noise',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: AppColors.glitch800,
                        height: 1.0,
                      ),
                      textHeightBehavior: TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Enter Your Private Key',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _keyController,
                      decoration: const InputDecoration(
                        hintText: 'nsec...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.glitch700,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.glitch700,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.glitch700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.glitch700),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.paste, size: 20),
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomFilledButton(
          onPressed: _onContinuePressed,
          title: 'Login',
        ),
      ),
    );
  }
}
