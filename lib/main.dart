import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/router_provider.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  final log = Logger('Whitenoise');

  final container = ProviderContainer();
  final authNotifier = container.read(authProvider.notifier);

  try {
    await authNotifier.initialize();
    log.info('Whitenoise initialized via authProvider');
  } catch (e) {
    log.severe('Initialization failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final router = ref.watch(routerProvider);

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
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.glitch950,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
            ),
          ),
          routerConfig: router,
        );
      },
    );
  }
}
