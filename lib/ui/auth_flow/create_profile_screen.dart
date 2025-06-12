import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/core/ui/custom_filled_button.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  void _onContinuePressed() {
    _usernameController.text.trim();
    _bioController.text.trim();
    context.go('/onboarding/key-created');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Center(
                child: Text(
                  'Set up your profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),
              const CircleAvatar(backgroundColor: AppColors.black, radius: 40),
              const SizedBox(height: 12),
              const Text(
                'Upload photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose a username',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: 'Enter name...',
                  filled: true,
                  fillColor: AppColors.glitch100,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add a short bio',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 1,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: 'A quick note about you...',
                  filled: true,
                  fillColor: AppColors.glitch100,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomFilledButton(onPressed: _onContinuePressed, title: 'Continue'),
      ),
    );
  }
}
