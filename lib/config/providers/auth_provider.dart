import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/config/providers/account_provider.dart';
import 'package:whitenoise/config/states/auth_state.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  /// Initialize Whitenoise and Rust backend
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Initialize Rust library
      await RustLib.init();

      /// 2. Create data and logs directories
      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/whitenoise/data';
      final logsDir = '${dir.path}/whitenoise/logs';

      await Directory(dataDir).create(recursive: true);
      await Directory(logsDir).create(recursive: true);

      /// 3. Create config and initialize Whitenoise instance
      final config = await createWhitenoiseConfig(
        dataDir: dataDir,
        logsDir: logsDir,
      );
      final whitenoise = await initializeWhitenoise(config: config);

      state = state.copyWith(whitenoise: whitenoise);

      /// 4. Auto-login if an account is already active
      final active = await getActiveAccount(whitenoise: state.whitenoise!);
      state = state.copyWith(isAuthenticated: active != null);
    } catch (e, st) {
      debugPrintStack(label: 'AuthState.initialize', stackTrace: st);
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
      state = state.copyWith(
        error:
            'Could not initialize Whitenoise: $previousError, account creation failed.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await createIdentity(whitenoise: state.whitenoise!);
      state = state.copyWith(isAuthenticated: true);

      // Load account data after creating identity
      await ref.read(accountProvider.notifier).loadAccount();
    } catch (e, st) {
      debugPrintStack(label: 'AuthState.createAccount', stackTrace: st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Login with a private key (nsec or hex)
  Future<void> loginWithKey(String nsecOrPrivkey) async {
    if (state.whitenoise == null) {
      await initialize();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      /// 1. Perform login using Rust API
      final account = await login(
        whitenoise: state.whitenoise!,
        nsecOrHexPrivkey: nsecOrPrivkey.trim(),
      );

      /// 2. Mark the account as active
      await updateActiveAccount(
        whitenoise: state.whitenoise!,
        account: account,
      );
      state = state.copyWith(isAuthenticated: true);

      // Load account data after login
      await ref.read(accountProvider.notifier).loadAccount();
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
      debugPrintStack(label: 'AuthState.loginWithKey', stackTrace: st);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Get the currently active account (if any)
  Future<Account?> getCurrentActiveAccount() async {
    if (state.whitenoise == null) {
      await initialize();
    }
    try {
      return await getActiveAccount(whitenoise: state.whitenoise!);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Logout the currently active account (if any)
  Future<void> logoutCurrentAccount() async {
    if (state.whitenoise == null) {
      state = state.copyWith(isAuthenticated: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final active = await getActiveAccount(whitenoise: state.whitenoise!);
      if (active != null) {
        await logout(whitenoise: state.whitenoise!, account: active);
      }
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
      debugPrintStack(label: 'AuthState.logoutCurrentAccount', stackTrace: st);
    } finally {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
