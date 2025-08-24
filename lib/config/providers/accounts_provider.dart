// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as wn_accounts_api;

class AccountsState {
  final String? activeAccountPubkey;
  final Map<String, wn_accounts_api.Account>? accountsMap;

  const AccountsState({
    this.activeAccountPubkey,
    this.accountsMap,
  });

  AccountsState copyWith({
    String? activeAccountPubkey,
    Map<String, wn_accounts_api.Account>? accountsMap,
  }) => AccountsState(
    activeAccountPubkey: activeAccountPubkey ?? this.activeAccountPubkey,
    accountsMap: accountsMap ?? this.accountsMap,
  );
}

class AccountsNotifier extends Notifier<AccountsState> {
  static const String _activeAccountPubkey = 'active_account_pubkey';
  final _logger = Logger('AccountsNotifier');

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  AccountsState build() {
    _loadActiveAccountPubkey();
    return const AccountsState();
  }

  Future<void> _loadActiveAccountPubkey() async {
    try {
      final activeAccountPubkey = await _storage.read(key: _activeAccountPubkey);
      if (activeAccountPubkey != null && activeAccountPubkey.isNotEmpty) {
        state = state.copyWith(activeAccountPubkey: activeAccountPubkey);
        _logger.info('Loaded active account: $activeAccountPubkey');
      }
    } catch (e) {
      _logger.severe('Error loading active account from storage: $e');
    }
  }

  Future<void> setActiveAccountPubkey(String pubkey) async {
    if (pubkey.isEmpty) {
      _logger.warning('Attempted to set empty pubkey as active account');
      return;
    }

    try {
      await _storage.write(key: _activeAccountPubkey, value: pubkey);
      state = state.copyWith(activeAccountPubkey: pubkey);
      _logger.info('Set active account: $pubkey');
    } catch (e) {
      _logger.severe('Error setting active account: $e');
    }
  }

  Future<void> clearActiveAccountPubkey() async {
    try {
      await _storage.delete(key: _activeAccountPubkey);
      state = state.copyWith(activeAccountPubkey: null);
      _logger.info('Cleared active account');
    } catch (e) {
      _logger.severe('Error clearing active account: $e');
    }
  }

  Future<void> loadAccounts() async {
    final accountsList = await wn_accounts_api.getAccounts();
    final accountsMap = <String, wn_accounts_api.Account>{};

    for (final account in accountsList) {
      accountsMap[account.pubkey] = account;
    }

    state = state.copyWith(accountsMap: accountsMap);
  }

  bool isActiveAccountPubkeyEmpty() {
    final activeAccountPubkey = state.activeAccountPubkey;
    if (activeAccountPubkey == null || activeAccountPubkey.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  bool isAccountsMapEmpty() {
    final accountsMap = state.accountsMap;
    if (accountsMap == null || accountsMap.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  Future<void> loadActiveAccountPubkeyIfNeeded() async {
    if (isActiveAccountPubkeyEmpty()) {
      await _loadActiveAccountPubkey();
    }
    return;
  }

  Future<void> loadAccountsMapIfNeeded() async {
    if (isAccountsMapEmpty()) {
      await loadAccounts();
    }
    return;
  }

  Future<String?> readActiveAccountPubkey() async {
    await loadActiveAccountPubkeyIfNeeded();
    if (isActiveAccountPubkeyEmpty()) {
      return null;
    } else {
      return state.activeAccountPubkey;
    }
  }

  Future<Map<String, wn_accounts_api.Account>> readAccountsMap() async {
    await loadAccountsMapIfNeeded();
    if (isAccountsMapEmpty()) {
      return {};
    }
    return state.accountsMap ?? {};
  }

  Future<List<wn_accounts_api.Account>> readAccounts() async {
    final accountsMap = await readAccountsMap();
    return accountsMap.values.toList();
  }

  Future<wn_accounts_api.Account?> readActiveAccount() async {
    final activeAccountPubkey = await readActiveAccountPubkey();
    if (isActiveAccountPubkeyEmpty()) {
      return null;
    }
    final accountsMap = await readAccountsMap();
    return accountsMap[activeAccountPubkey];
  }

  Future<wn_accounts_api.Account?> createAccount() async {
    final account = await wn_accounts_api.createIdentity();
    await loadAccounts();
    await setActiveAccountPubkey(account.pubkey);
    return account;
  }

  Future<void> clearAllSecureStorage() async {
    try {
      await _storage.deleteAll();
      _logger.info('AccountsProvider: Cleared all secure storage data');
    } catch (e) {
      _logger.severe('AccountsProvider: Error clearing all secure storage: $e');
    }
  }
}

final accountsProvider = NotifierProvider<AccountsNotifier, AccountsState>(
  AccountsNotifier.new,
);
