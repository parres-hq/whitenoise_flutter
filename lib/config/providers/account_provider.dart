import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/src/rust/api.dart';

class AccountState {
  final Account? account;
  final String? pubkey;
  final Map<String, AccountData>? accounts;
  final bool isLoading;
  final String? error;

  const AccountState({
    this.account,
    this.pubkey,
    this.accounts,
    this.isLoading = false,
    this.error,
  });

  AccountState copyWith({
    Account? account,
    String? pubkey,
    Map<String, AccountData>? accounts,
    bool? isLoading,
    String? error,
  }) => AccountState(
    account: account ?? this.account,
    pubkey: pubkey ?? this.pubkey,
    accounts: accounts ?? this.accounts,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
  );
}

class AccountNotifier extends Notifier<AccountState> {
  @override
  AccountState build() => const AccountState();

  // Load the currently active account
  Future<void> loadAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    final wn = ref.read(authProvider).whitenoise;
    if (wn == null) {
      state = state.copyWith(
        error: 'Whitenoise instance not found',
        isLoading: false,
      );
      return;
    }

    try {
      final acct = await getActiveAccount(whitenoise: wn);
      if (acct == null) {
        state = state.copyWith(error: 'No active account found');
      } else {
        final data = await getAccountData(account: acct);
        state = state.copyWith(account: acct, pubkey: data.pubkey);
      }
    } catch (e, st) {
      debugPrintStack(label: 'loadAccount', stackTrace: st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Fetch and store all accounts
  Future<Map<String, AccountData>?> listAccounts() async {
    final wn = ref.read(authProvider).whitenoise;
    if (wn == null) return null;

    try {
      final wnData = await getWhitenoiseData(whitenoise: wn);
      state = state.copyWith(accounts: wnData.accounts);
      return wnData.accounts;
    } catch (e, st) {
      debugPrintStack(label: 'listAccounts', stackTrace: st);
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Set a specific account as active
  Future<void> setActiveAccount(Account account) async {
    final wn = ref.read(authProvider).whitenoise;
    if (wn == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await updateActiveAccount(
        whitenoise: wn,
        account: account,
      );
      final data = await getAccountData(account: updated);
      state = state.copyWith(account: updated, pubkey: data.pubkey);
    } catch (e, st) {
      debugPrintStack(label: 'setActiveAccount', stackTrace: st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Return pubkey (load account if missing)
  Future<String?> getPubkey() async {
    if (state.pubkey != null) return state.pubkey;
    await loadAccount();
    return state.pubkey;
  }

  // Update metadata for the current account
  Future<void> updateAccountMetadata(Metadata metadata) async {
    final wn = ref.read(authProvider).whitenoise;
    final acct = state.account;
    if (wn == null || acct == null) return;

    state = state.copyWith(isLoading: true);
    try {
      await updateMetadata(whitenoise: wn, metadata: metadata, account: acct);
    } catch (e, st) {
      debugPrintStack(label: 'updateMetadata', stackTrace: st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final accountProvider = NotifierProvider<AccountNotifier, AccountState>(
  AccountNotifier.new,
);
