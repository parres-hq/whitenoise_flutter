// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/src/rust/api.dart';

class AccountState {
  final Account? account;
  final MetadataData? metadata;
  final String? pubkey;
  final Map<String, AccountData>? accounts;
  final bool isLoading;
  final String? error;

  const AccountState({
    this.account,
    this.metadata,
    this.pubkey,
    this.accounts,
    this.isLoading = false,
    this.error,
  });

  AccountState copyWith({
    Account? account,
    MetadataData? metadata,
    String? pubkey,
    Map<String, AccountData>? accounts,
    bool? isLoading,
    String? error,
  }) => AccountState(
    account: account ?? this.account,
    metadata: metadata ?? this.metadata,
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
  Future<void> loadAccountData() async {
    state = state.copyWith(isLoading: true, error: null);

    if (!ref.read(authProvider).isAuthenticated) {
      state = state.copyWith(
        error: 'Not authenticated',
        isLoading: false,
      );
      return;
    }

    try {
      // Get the active account data from active account provider
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();

      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
      } else {
        final publicKey = await publicKeyFromString(
          publicKeyString: activeAccountData.pubkey,
        );
        final metadata = await fetchMetadata(pubkey: publicKey);

        // We need to create a dummy Account object since we only have AccountData
        // This is a limitation of the current API design
        state = state.copyWith(
          account: null, // We don't have the actual Account object
          metadata: metadata,
          pubkey: activeAccountData.pubkey,
        );

        // Automatically load contacts for the active account
        try {
          await ref.read(contactsProvider.notifier).loadContacts(activeAccountData.pubkey);
        } catch (e) {
          debugPrint('Failed to load contacts: $e');
        }
      }
    } catch (e, st) {
      debugPrintStack(label: 'loadAccountData', stackTrace: st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Fetch and store all accounts
  Future<List<AccountData>?> listAccounts() async {
    try {
      final accountsList = await fetchAccounts();
      final accountsMap = <String, AccountData>{};
      for (final account in accountsList) {
        accountsMap[account.pubkey] = account;
      }
      state = state.copyWith(accounts: accountsMap);
      return accountsList;
    } catch (e, st) {
      debugPrintStack(label: 'listAccounts', stackTrace: st);
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Set a specific account as active
  Future<void> setActiveAccount(Account account) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await getAccountData(account: account);
      state = state.copyWith(account: account, pubkey: data.pubkey);

      // Automatically load contacts for the newly active account
      try {
        await ref.read(contactsProvider.notifier).loadContacts(data.pubkey);
      } catch (e) {
        debugPrint('Failed to load contacts: $e');
      }
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
    await loadAccountData();
    return state.pubkey;
  }

  // Update metadata for the current account
  Future<void> updateAccountMetadata(String displayName, String bio) async {
    final acct = state.account;
    if (acct == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final accountMetadata = state.metadata;
      if (accountMetadata != null) {
        if (displayName.isNotEmpty && displayName != accountMetadata.displayName) {
          accountMetadata.displayName = displayName;
          accountMetadata.about = bio;

          await updateMetadata(
            metadata: accountMetadata,
            account: acct,
          );
        }
      } else {
        throw Exception('No metadata found');
      }
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
