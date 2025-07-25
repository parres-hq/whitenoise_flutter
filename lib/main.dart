import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/theme_provider.dart';
import 'package:whitenoise/routing/router_provider.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';
import 'package:whitenoise/ui/core/ui/wn_toast.dart';

import 'ui/core/themes/src/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Logging
  Logger.root.level = Level.ALL;
  final log = Logger('Whitenoise');

  // Initialize Rust library first
  try {
    await RustLib.init();
    log.info('Rust library initialized successfully');
  } catch (e) {
    log.severe('Failed to initialize Rust library: $e');
    rethrow;
  }

  final container = ProviderContainer();
  final authNotifier = container.read(authProvider.notifier);
  container.read(themeProvider.notifier);

  try {
    await authNotifier.initialize();
    log.info('Whitenoise initialized via authProvider');
  } catch (e) {
    log.severe('Initialization failed: $e');
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);

    return ScreenUtilInit(
      designSize: width > 600 ? const Size(600, 1024) : const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'White Noise',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeState.themeMode,
          routerConfig: router,
          builder: (context, child) {
            return WnToast(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
