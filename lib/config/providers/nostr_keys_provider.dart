import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/nostr_keys_state.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/utils/string_extensions.dart';

final _logger = Logger('NostrKeysNotifier');

class NostrKeysNotifier extends Notifier<NostrKeysState> {
  @override
  NostrKeysState build() {
    return const NostrKeysState();
  }

  /// Load both public and private keys from the active account
  Future<void> loadKeys() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check authentication first
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        _logger.warning('NostrKeysNotifier: User not authenticated');
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        _logger.severe('NostrKeysNotifier: No active account found');
        state = state.copyWith(
          isLoading: false,
          error: 'No active account found',
        );
        return;
      }

      _logger.info('NostrKeysNotifier: Loading keys for account: $activePubkey');

      // Load npub and nsec directly from hex pubkey string
      final activeNpub = await activePubkey.toNpub();
      final activeNsec = await exportAccountNsec(pubkey: activePubkey);

      state = state.copyWith(
        npub: activeNpub,
        nsec: activeNsec,
        isLoading: false,
        error: null,
      );

      _logger.info('NostrKeysNotifier: Keys loaded successfully');
    } catch (e) {
      _logger.severe('NostrKeysNotifier: Error loading keys: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading keys: $e',
      );
    }
  }

  /// Load public key from Account directly (fallback method)
  void loadPublicKeyFromAccount(String pubkey) {
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
}

final nostrKeysProvider = NotifierProvider<NostrKeysNotifier, NostrKeysState>(
  NostrKeysNotifier.new,
);
