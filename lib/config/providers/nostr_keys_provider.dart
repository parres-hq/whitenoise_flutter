import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/nostr_keys_state.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

final _logger = Logger('NostrKeysNotifier');

final nostrKeysProvider = NotifierProvider<NostrKeysNotifier, NostrKeysState>(
  NostrKeysNotifier.new,
);

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

      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();

      if (activeAccountData == null) {
        _logger.severe('NostrKeysNotifier: No active account found');
        state = state.copyWith(
          isLoading: false,
          error: 'No active account found',
        );
        return;
      }

      _logger.info('NostrKeysNotifier: Loading keys for account: ${activeAccountData.pubkey}');

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);

      // Load npub and nsec
      final npubString = await exportAccountNpub(pubkey: publicKey);
      final nsecString = await exportAccountNsec(pubkey: publicKey);

      state = state.copyWith(
        npub: npubString,
        nsec: nsecString,
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

  /// Load public key from AccountData directly (fallback method)
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
