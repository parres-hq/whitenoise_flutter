import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/config/states/auth_state.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  /// Initialize the Rust side and start Whitenoise with the config
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RustLib.init();

      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/whitenoise/data';
      final logsDir = '${dir.path}/whitenoise/logs';

      await Directory(dataDir).create(recursive: true);
      await Directory(logsDir).create(recursive: true);

      final config = await createWhitenoiseConfig(dataDir: dataDir, logsDir: logsDir);
      final whitenoise = await initializeWhitenoise(config: config);

      state = state.copyWith(whitenoise: whitenoise);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Create a new account and set it as active
  Future<void> createAccount() async {
    if (state.whitenoise == null) {
      await initialize();
    }

    if (state.whitenoise == null) {
      final previousError = state.error;
      state = state.copyWith(error: "Could not initialize Whitenoise: $previousError, account creation failed.");
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final account = await createIdentity(whitenoise: state.whitenoise!);
      await updateActiveAccount(whitenoise: state.whitenoise!, account: account);
      state = state.copyWith(isAuthenticated: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
