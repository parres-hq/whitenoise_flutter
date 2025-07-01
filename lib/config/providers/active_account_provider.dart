import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

/// Active Account Provider
///
/// Manages the currently active account using Flutter Secure Storage for persistence.
/// Uses the new fetchAccount() API for better performance when getting account data.

class ActiveAccountNotifier extends Notifier<String?> {
  static const String _activeAccountKey = 'active_account_pubkey';
  final _logger = Logger('ActiveAccountProvider');

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  String? build() {
    loadActiveAccount();
    return null;
  }

  Future<void> loadActiveAccount() async {
    try {
      final activeAccountPubkey = await _storage.read(key: _activeAccountKey);
      _logger.info('ActiveAccountProvider: Loaded active account: $activeAccountPubkey');
      state = activeAccountPubkey;
    } catch (e) {
      _logger.severe('Error loading active account: $e');
      state = null;
    }
  }

  Future<void> setActiveAccount(String pubkey) async {
    try {
      await _storage.write(key: _activeAccountKey, value: pubkey);
      _logger.info('ActiveAccountProvider: Set active account: $pubkey');
      state = pubkey;
    } catch (e) {
      _logger.severe('Error setting active account: $e');
    }
  }

  Future<void> clearActiveAccount() async {
    try {
      await _storage.delete(key: _activeAccountKey);
      state = null;
    } catch (e) {
      _logger.severe('ActiveAccountProvider: Error clearing active account: $e');
    }
  }

  Future<AccountData?> getActiveAccountData() async {
    _logger.info('Getting active account data, state: $state');
    if (state == null) {
      _logger.warning('No active account set');
      return null;
    }

    try {
      // Use the new fetchAccount API function for better performance
      final publicKey = await publicKeyFromString(publicKeyString: state!);
      final activeAccount = await fetchAccount(pubkey: publicKey);
      _logger.info('Found active account: ${activeAccount.pubkey}');
      return activeAccount;
    } catch (e) {
      _logger.warning('Error with new fetchAccount API: $e');
      // Fallback to the old method if the new one fails
      try {
        final accounts = await fetchAccounts();
        _logger.info('Fallback - Found ${accounts.length} accounts');
        final activeAccount = accounts.firstWhere(
          (account) => account.pubkey == state,
          orElse: () => throw Exception('Active account not found'),
        );
        _logger.info('Fallback - Found active account: ${activeAccount.pubkey}');
        return activeAccount;
      } catch (fallbackError) {
        _logger.severe('Fallback method also failed: $fallbackError');
        return null;
      }
    }
  }

  /// Clear all secure storage data (useful for debugging or complete reset)
  Future<void> clearAllSecureStorage() async {
    try {
      await _storage.deleteAll();
      _logger.info('ActiveAccountProvider: Cleared all secure storage data');
    } catch (e) {
      _logger.severe('ActiveAccountProvider: Error clearing all secure storage: $e');
    }
  }
}

final activeAccountProvider = NotifierProvider<ActiveAccountNotifier, String?>(
  ActiveAccountNotifier.new,
);
