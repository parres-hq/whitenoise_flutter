import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/ui/auth_flow/info_screen.dart';
import 'package:whitenoise/ui/auth_flow/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: screenHeight * 0.55,
            width: double.infinity,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.black, AppColors.transparent],
                  stops: [0.7, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(AssetsPaths.loginSplash, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 44, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Welcome to',
                  style: TextStyle(fontSize: 24, color: AppColors.black),
                ),
                SizedBox(height: 4),
                Text(
                  'White Noise',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Private messaging made easy.',
                  style: TextStyle(fontSize: 18, color: AppColors.grey3),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: TextButton(
                style: ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(AppColors.transparent),
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InfoScreen()),
                  );
                },
                child: const Text(
                  'Create a new profile',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 96,
            width: double.infinity,
            color: AppColors.black,
            padding: const EdgeInsets.only(top: 20),
            child: TextButton(
              style: ButtonStyle(
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(AppColors.transparent),
                padding: WidgetStateProperty.all(EdgeInsets.zero),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'Sign in',
                  style: TextStyle(fontSize: 18, color: AppColors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
