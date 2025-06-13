import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Rust-generated bridge API
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

class AuthState with ChangeNotifier {
  /// ---------- Private fields ----------
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  Whitenoise? _whitenoise;

  /// ---------- Public getters ----------
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Whitenoise? get whitenoise => _whitenoise;

  /// Initialize Whitenoise and Rust backend
  Future<void> initialize() async {
    _setLoading(true);
    _error = null;

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
      _whitenoise = await initializeWhitenoise(config: config);

      /// 4. Auto-login if an account is already active
      final active = await getActiveAccount(whitenoise: _whitenoise!);
      _isAuthenticated = active != null;
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(label: 'AuthState.initialize', stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new account and set it as active
  Future<void> createAccount() async {
    if (_whitenoise == null) {
      _error = 'Whitenoise is not initialized';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final account = await createIdentity(whitenoise: _whitenoise!);
      await updateActiveAccount(whitenoise: _whitenoise!, account: account);
      _isAuthenticated = true;
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(label: 'AuthState.createAccount', stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  /// Login with a private key (nsec or hex)
  Future<void> loginWithKey(String nsecOrPrivkey) async {
    if (_whitenoise == null) {
      _error = 'Whitenoise is not initialized';
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      /// 1. Perform login using Rust API
      final account = await login(
        whitenoise: _whitenoise!,
        nsecOrHexPrivkey: nsecOrPrivkey.trim(),
      );

      /// 2. Mark the account as active
      await updateActiveAccount(whitenoise: _whitenoise!, account: account);
      _isAuthenticated = true;
    } catch (e, st) {
      _error = e.toString();
      _isAuthenticated = false;
      debugPrintStack(label: 'AuthState.loginWithKey', stackTrace: st);
    } finally {
      _setLoading(false);
    }
  }

  /// Get the currently active account (if any)
  Future<Account?> getCurrentActiveAccount() async {
    if (_whitenoise == null) return null;

    try {
      return await getActiveAccount(whitenoise: _whitenoise!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Logout the currently active account (if any)
  Future<void> logoutCurrentAccount() async {
    if (_whitenoise == null) {
      _isAuthenticated = false;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final active = await getActiveAccount(whitenoise: _whitenoise!);
      if (active != null) {
        await logout(whitenoise: _whitenoise!, account: active);
      }
    } catch (e, st) {
      _error = e.toString();
      debugPrintStack(label: 'AuthState.logoutCurrentAccount', stackTrace: st);
    } finally {
      _isAuthenticated = false;
      _setLoading(false);
    }
  }

  /// Helper to update loading state and notify listeners
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

/// Riverpod provider for authentication state
final authProvider = ChangeNotifierProvider<AuthState>((ref) => AuthState());
