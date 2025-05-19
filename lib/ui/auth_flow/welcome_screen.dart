import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/auth_flow/info_page.dart';
import 'package:whitenoise/ui/auth_flow/login_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
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
                  colors: [Colors.black, Colors.transparent],
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
                  style: TextStyle(fontSize: 24, color: Colors.black87),
                ),
                SizedBox(height: 4),
                Text(
                  'White Noise',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Private messaging made easy.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
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
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InfoPage()),
                  );
                },
                child: const Text(
                  'Create a new profile',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),

          Container(
            height: 96,
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.only(top: 20),
            child: TextButton(
              style: ButtonStyle(
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                padding: WidgetStateProperty.all(EdgeInsets.zero),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'Sign in',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
