import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';

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
  Future<void> exportNsec() async {
    _setLoading(true);
    _error = null;

    try {
      // TODO: This functionality requires access to providers which is not available in this context
      // For now, show a message that export is not implemented
      _error = 'Private key export not implemented yet - use copy button instead';
      _nsec = null;
    } catch (e) {
      _error = e.toString();
      _nsec = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get the public key (npub) from the current active account
  /// Public keys are safe to display and don't require the same security measures as private keys
  Future<void> loadPublicKey() async {
    try {
      // We can't use the Account-based API, but we can show the pubkey from AccountData
      // This is a workaround until we can properly convert AccountData to Account

      _npub = 'Public key will be loaded from active account data';
      _error = null;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _npub = null;
      notifyListeners();
    }
  }

  /// Load public key from AccountData directly
  void loadPublicKeyFromAccountData(String pubkey) {
    _npub = pubkey;
    _error = null;
    notifyListeners();
  }

  /// Set private key directly (for external loading)
  void setNsec(String nsec) {
    _nsec = nsec;
    _error = null;
    notifyListeners();
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

// Helper provider that automatically loads keys when we have an active account
final currentAccountKeysProvider = FutureProvider<void>((ref) async {
  final activeAccountData = await ref.watch(activeAccountProvider.notifier).getActiveAccountData();
  
  if (activeAccountData != null) {
    final nostrKeys = ref.read(nostrKeysProvider);
    await nostrKeys.loadPublicKey();
  }
});
