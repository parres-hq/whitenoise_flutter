import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/states/nostr_keys_state.dart';
import 'package:whitenoise/utils/string_extensions.dart';

final nostrKeysProvider = NotifierProvider<NostrKeysNotifier, NostrKeysState>(
  NostrKeysNotifier.new,
);

class NostrKeysNotifier extends Notifier<NostrKeysState> {
  @override
  NostrKeysState build() {
    // Auto-load public key when we have an active account
    _loadPublicKeyFromActiveAccount();
    return const NostrKeysState();
  }

  /// Export the private key (nsec) from the current active account
  /// This should be used carefully and the key should not be stored longer than necessary
  Future<void> exportNsec() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: This functionality requires access to providers which is not available in this context
      // For now, show a message that export is not implemented
      state = state.copyWith(
        isLoading: false,
        error: 'Private key export not implemented yet - use copy button instead',
        nsec: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        nsec: null,
      );
    }
  }

  /// Get the public key (npub) from the current active account
  /// Public keys are safe to display and don't require the same security measures as private keys
  Future<void> loadPublicKey() async {
    try {
      // We can't use the Account-based API, but we can show the pubkey from AccountData
      // This is a workaround until we can properly convert AccountData to Account
      state = state.copyWith(
        npub: 'Public key will be loaded from active account data',
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        npub: null,
      );
    }
  }

  /// Load public key from AccountData directly
  void loadPublicKeyFromAccountData(String pubkey) {
    state = state.copyWith(
      npub: pubkey,
      error: null,
    );
  }

  /// Set private key directly (for external loading)
  void setNsec(String nsec) {
    state = state.copyWith(
      nsec: nsec,
      error: null,
    );
  }

  /// Clear the private key from memory
  /// This should be called when the private key is no longer needed
  void clearNsec() {
    state = state.copyWith(
      nsec: null,
      error: null,
    );
  }

  /// Clear all keys from memory (both private and public)
  void clearAllKeys() {
    state = state.copyWith(
      nsec: null,
      npub: null,
      error: null,
    );
  }

  /// Auto-load public key when we have an active account
  Future<void> _loadPublicKeyFromActiveAccount() async {
    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();

      if (activeAccountData != null) {
        // Convert pubkey to npub format
        final npub = await activeAccountData.pubkey.toNpub();
        if (npub != null) {
          loadPublicKeyFromAccountData(npub);
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Helper provider that automatically loads keys when we have an active account
final currentAccountKeysProvider = FutureProvider<void>((ref) async {
  final activeAccountData = await ref.watch(activeAccountProvider.notifier).getActiveAccountData();

  if (activeAccountData != null) {
    // Convert pubkey to npub format
    final npub = await activeAccountData.pubkey.toNpub();
    if (npub != null) {
      ref.read(nostrKeysProvider.notifier).loadPublicKeyFromAccountData(npub);
    }
  }
});
