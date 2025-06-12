import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/frb_generated.dart';

class AuthState with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  Whitenoise? _whitenoise;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Whitenoise? get whitenoise => _whitenoise;

  /// Initialize the Rust side and start Whitenoise with the config
  Future<void> initialize() async {
    _setLoading(true);
    _error = null;

    try {
      // Load RustLib
      await RustLib.init();

      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/whitenoise/data';
      final logsDir = '${dir.path}/whitenoise/logs';

      await Directory(dataDir).create(recursive: true);
      await Directory(logsDir).create(recursive: true);

      final config = await createWhitenoiseConfig(dataDir: dataDir, logsDir: logsDir);
      _whitenoise = await initializeWhitenoise(config: config);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new account and set it as active
  Future<void> createAccount() async {
    if (_whitenoise == null) {
      _error = "Whitenoise not initialized";
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;

    try {
      final account = await createIdentity(whitenoise: _whitenoise!);
      await updateActiveAccount(whitenoise: _whitenoise!, account: account);
      _isAuthenticated = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Get the active account if available
  Future<Account?> getCurrentActiveAccount() async {
    if (_whitenoise == null) return null;
    
    try {
      return await getActiveAccount(whitenoise: _whitenoise!);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    
    return null;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}

final authProvider = ChangeNotifierProvider<AuthState>((ref) => AuthState());
