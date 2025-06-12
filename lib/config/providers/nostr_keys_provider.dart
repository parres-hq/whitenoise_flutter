import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/src/rust/api.dart';

class NostrKeysState with ChangeNotifier {
  String? _nsec;
  String? _npub;
  bool _isLoading = false;
  String? _error;

  String? get nsec => _nsec;
  String? get npub => _npub;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Export the private key (nsec) from the current active account
  /// This should be used carefully and the key should not be stored longer than necessary
  Future<void> exportNsec({
    required Whitenoise whitenoise,
    required Account account,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Get the nsec string directly from the rust side (updated bridge method)
      final nsecString = await exportAccountNsec(
        whitenoise: whitenoise,
        account: account,
      );

      _nsec = nsecString;
    } catch (e) {
      _error = e.toString();
      _nsec = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get the public key (npub) from the current active account
  /// Public keys are safe to display and don't require the same security measures as private keys
  Future<void> loadPublicKey({
    required Whitenoise whitenoise,
    required Account account,
  }) async {
    try {
      // Use the new exportAccountNpub method to get the properly formatted npub1 key
      final npubString = await exportAccountNpub(
        whitenoise: whitenoise,
        account: account,
      );

      _npub = npubString;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _npub = null;
      notifyListeners();
    }
  }

  /// Clear the private key from memory
  /// This should be called when the private key is no longer needed
  void clearNsec() {
    _nsec = null;
    _error = null;
    notifyListeners();
  }

  /// Clear all keys from memory (both private and public)
  void clearAllKeys() {
    _nsec = null;
    _npub = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    // Ensure we clear sensitive data when disposing
    clearAllKeys();
    super.dispose();
  }
}

// Provider for NostrKeysState
final nostrKeysProvider = ChangeNotifierProvider<NostrKeysState>((ref) {
  final keys = NostrKeysState();

  // Auto-dispose and clear when the provider is disposed
  ref.onDispose(() {
    keys.clearAllKeys();
  });

  return keys;
});

// Helper provider that automatically exports nsec when we have an account
final currentAccountProvider = FutureProvider<Account?>((ref) async {
  final auth = ref.watch(authProvider);

  if (auth.whitenoise != null) {
    return await auth.getCurrentActiveAccount();
  }

  return null;
});
