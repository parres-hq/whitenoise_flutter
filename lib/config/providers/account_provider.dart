// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/src/rust/api.dart';

class AccountState {
  final Account? account;
  final Metadata? metadata;
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
    Metadata? metadata,
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
        final accountData = await getAccountData(account: acct);

        final publicKey = await publicKeyFromString(
          publicKeyString: accountData.pubkey,
        );
        final metadata = await fetchMetadata(
          whitenoise: wn,
          pubkey: publicKey,
        );

        state = state.copyWith(
          account: acct,
          metadata: metadata,
          pubkey: accountData.pubkey,
        );

        // Automatically load contacts for the active account
        try {
          await ref.read(contactsProvider.notifier).loadContacts(data.pubkey);
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

    state = state.copyWith(isLoading: true);
    try {
      final updated = await updateActiveAccount(
        whitenoise: wn,
        account: account,
      );
      final data = await getAccountData(account: updated);
      state = state.copyWith(account: updated, pubkey: data.pubkey);

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
    final wn = ref.read(authProvider).whitenoise;
    final acct = state.account;
    if (wn == null || acct == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final accountMetadata = state.metadata;
      if (accountMetadata != null) {
        if (displayName.isNotEmpty &&
            displayName != accountMetadata.displayName) {
          accountMetadata.displayName = displayName;
          //TODO: impl bio for Metadata
          // accountMetadata.bio = bio;

          final updatedMetadata = accountMetadata;
          await updateMetadata(
            whitenoise: wn,
            metadata: updatedMetadata,
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
