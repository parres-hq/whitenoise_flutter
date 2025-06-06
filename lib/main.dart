import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/routing/router_provider.dart';
import 'package:flutter/services.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Rust library
  try {
    await RustLib.init();
    print('✅ Rust library initialized successfully');

    // Initialize Whitenoise with proper config
    try {
      // Get application directories
      final appDir = await getApplicationDocumentsDirectory();
      final dataDir = '${appDir.path}/whitenoise/data';
      final logsDir = '${appDir.path}/whitenoise/logs';

      // Create directories if they don't exist
      await Directory(dataDir).create(recursive: true);
      await Directory(logsDir).create(recursive: true);

      print('📁 Data directory: $dataDir');
      print('📁 Logs directory: $logsDir');

      // Create WhitenoiseConfig
      final config = await createWhitenoiseConfig(
        dataDir: dataDir,
        logsDir: logsDir,
      );
      print('✅ WhitenoiseConfig created successfully');

      // Initialize Whitenoise
      final whitenoise = await initializeWhitenoise(config: config);
      print('🚀 Whitenoise initialized successfully!');
      print('📱 White Noise is ready to use');

    } catch (e) {
      print('⚠️ Whitenoise initialization failed: $e');
      print('   Check if all dependencies are properly configured');
    }
  } catch (e) {
    print('❌ Failed to initialize Rust library: $e');
  }

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
