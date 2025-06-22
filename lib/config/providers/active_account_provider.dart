import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/src/rust/api.dart';

/// Active Account Provider
///
/// Manages the currently active account using SharedPreferences for persistence.
/// Uses the new fetchAccount() API for better performance when getting account data.

class ActiveAccountNotifier extends Notifier<String?> {
  static const String _activeAccountKey = 'active_account_pubkey';

  @override
  String? build() {
    _loadActiveAccount();
    return null;
  }

  Future<void> _loadActiveAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeAccountPubkey = prefs.getString(_activeAccountKey);
      print('ActiveAccountProvider: Loaded active account: $activeAccountPubkey');
      state = activeAccountPubkey;
    } catch (e) {
      print('ActiveAccountProvider: Error loading active account: $e');
      state = null;
    }
  }

  Future<void> setActiveAccount(String pubkey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeAccountKey, pubkey);
      print('ActiveAccountProvider: Set active account: $pubkey');
      state = pubkey;
    } catch (e) {
      print('ActiveAccountProvider: Error setting active account: $e');
    }
  }

  Future<void> clearActiveAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeAccountKey);
      state = null;
    } catch (e) {
      // Handle error
    }
  }

  Future<AccountData?> getActiveAccountData() async {
    print('ActiveAccountProvider: Getting active account data, state: $state');
    if (state == null) {
      print('ActiveAccountProvider: No active account set');
      return null;
    }

    try {
      // Use the new fetchAccount API function for better performance
      final publicKey = await publicKeyFromString(publicKeyString: state!);
      final activeAccount = await fetchAccount(pubkey: publicKey);
      print('ActiveAccountProvider: Found active account using new API: ${activeAccount.pubkey}');
      return activeAccount;
    } catch (e) {
      print('ActiveAccountProvider: Error with new fetchAccount API: $e');
      // Fallback to the old method if the new one fails
      try {
        final accounts = await fetchAccounts();
        print('ActiveAccountProvider: Fallback - Found ${accounts.length} accounts');
        final activeAccount = accounts.firstWhere(
          (account) => account.pubkey == state,
          orElse: () => throw Exception('Active account not found'),
        );
        print('ActiveAccountProvider: Fallback - Found active account: ${activeAccount.pubkey}');
        return activeAccount;
      } catch (fallbackError) {
        print('ActiveAccountProvider: Fallback method also failed: $fallbackError');
        return null;
      }
    }
  }
}

final activeAccountProvider = NotifierProvider<ActiveAccountNotifier, String?>(
  ActiveAccountNotifier.new,
);
