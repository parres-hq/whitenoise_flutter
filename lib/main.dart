import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/routing/router_provider.dart';
import 'package:flutter/services.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await RustLib.init();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final router = ref.watch(routerProvider);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Set status bar to light text for dark backgrounds
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // for Android
      statusBarBrightness: Brightness.dark, // for iOS
    ));

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
              backgroundColor: AppColors.glitch950, // Default AppBar color for the app
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light, // for Android
                statusBarBrightness: Brightness.dark, // for iOS
              ),
            ),
          ),
          routerConfig: router,
        );
      },
    );
  }
}
