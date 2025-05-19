import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/routing/router.dart';
import 'package:flutter/services.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await RustLib.init();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return ScreenUtilInit(
      designSize: width > 600 ? const Size(600, 1024) : const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'White Noise',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'OverusedGrotesk',
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.color202320, // Default AppBar color for the app
            ),
          ),
          routerConfig: router,
        );
      },
    );
  }
}
