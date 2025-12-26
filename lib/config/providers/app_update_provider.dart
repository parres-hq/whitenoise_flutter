import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whitenoise/src/rust/api/app_update.dart';

class AppUpdateState {
  final bool isLoading;
  final bool updateAvailable;
  final String? latestVersion;
  final String? error;
  final bool dismissed;

  const AppUpdateState({
    this.isLoading = false,
    this.updateAvailable = false,
    this.latestVersion,
    this.error,
    this.dismissed = false,
  });

  AppUpdateState copyWith({
    bool? isLoading,
    bool? updateAvailable,
    String? latestVersion,
    String? error,
    bool? dismissed,
  }) {
    return AppUpdateState(
      isLoading: isLoading ?? this.isLoading,
      updateAvailable: updateAvailable ?? this.updateAvailable,
      latestVersion: latestVersion ?? this.latestVersion,
      error: error,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  bool get shouldShowBanner => updateAvailable && !dismissed && !isLoading;
}

class AppUpdateNotifier extends Notifier<AppUpdateState> {
  final _logger = Logger('AppUpdateNotifier');

  @override
  AppUpdateState build() {
    Future.microtask(() => checkForUpdate());
    return const AppUpdateState(isLoading: true);
  }

  Future<void> checkForUpdate() async {
    if (state.isLoading && state.latestVersion != null) return;

    state = state.copyWith(isLoading: true);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      _logger.info('Checking for updates. Current version: $currentVersion');

      final updateInfo = await checkForAppUpdate(currentVersion: currentVersion);

      _logger.info(
        'Update check complete. Latest: ${updateInfo.version}, '
        'Update available: ${updateInfo.updateAvailable}',
      );

      state = state.copyWith(
        isLoading: false,
        updateAvailable: updateInfo.updateAvailable,
        latestVersion: updateInfo.version,
      );
    } catch (e) {
      _logger.warning('Failed to check for updates');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void dismissBanner() {
    state = state.copyWith(dismissed: true);
  }

  void resetDismissal() {
    state = state.copyWith(dismissed: false);
  }
}

final appUpdateProvider = NotifierProvider<AppUpdateNotifier, AppUpdateState>(
  AppUpdateNotifier.new,
);
