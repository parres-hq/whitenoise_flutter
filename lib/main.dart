import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/localization_provider.dart';
import 'package:whitenoise/config/providers/theme_provider.dart';
import 'package:whitenoise/domain/services/background_sync_service.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/routing/router_provider.dart';
import 'package:whitenoise/services/localization_service.dart';
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

  try {
    await RustLib.init();
    FlutterForegroundTask.initCommunicationPort();
    log.info('Rust library initialized successfully');
  } catch (e) {
    log.severe('Failed to initialize Rust library: $e');
    rethrow;
  }

  final container = ProviderContainer();
  final authNotifier = container.read(authProvider.notifier);
  final localizationNotifier = container.read(localizationProvider.notifier);
  container.read(themeProvider.notifier);

  try {
    // Initialize localization first
    await localizationNotifier.initialize();
    log.info('Localization initialized successfully');

    await authNotifier.initialize();
    log.info('Whitenoise initialized via authProvider');

    await NotificationService.initialize();
    await BackgroundSyncService.initWorkManager();
    await BackgroundSyncService.registerMetadataSyncTask();
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
    final currentLocale = ref.watch(currentLocaleProvider);

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
          locale: currentLocale,
          supportedLocales: LocalizationService.supportedLocaleObjects,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (context, child) {
            return WnToast(child: child ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
