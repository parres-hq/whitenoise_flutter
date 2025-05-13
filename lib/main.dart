import 'package:flutter/material.dart';
import 'package:whitenoise/screens/auth_flow/welcome_page.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'White Noise',
      theme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: const WelcomePage(),
    );
  }
}
