import 'package:flutter/material.dart';
import 'frb_accounts_screen.dart';

class FrbGeneralScreen extends StatelessWidget {
  const FrbGeneralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Whitenoise FRB Tests',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FrbAccountsScreen()),
                  );
                },
                child: const Text('Go to Accounts'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
