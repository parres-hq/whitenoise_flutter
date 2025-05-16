import 'package:flutter/material.dart';
import 'package:whitenoise/src/core/utils/app_colors.dart';
import 'package:whitenoise/src/pages/chat/chat_screen.dart';
import 'package:whitenoise/src/rust/api/simple.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

Future<void> main() async {
  //await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // return MaterialApp(
    //   home: Scaffold(
    //     appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
    //     body: Center(
    //       child: Text(
    //         'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`',
    //       ),
    //     ),
    //   ),
    // );
    return  MaterialApp(
      title: 'WhiteNoise',
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
      theme: ThemeData(
        fontFamily: 'OverusedGrotesk',
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.color202320, // Default AppBar color for the app
        ),
      ),
    );
  }
}
