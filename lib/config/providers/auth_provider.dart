import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/config/providers/account_provider.dart';
import 'package:whitenoise/config/providers/accounts_provider.dart';
import 'package:whitenoise/config/states/auth_state.dart';
import 'package:whitenoise/src/rust/api.dart'
    show createWhitenoiseConfig, initializeWhitenoise, WhitenoiseError;
import 'package:whitenoise/src/rust/api/accounts.dart' as wn_accounts_api;
import 'package:whitenoise/src/rust/api/error.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:flutter/foundation.dart';

/// Auth Provider
///
/// This provider manages authentication using the new PublicKey-based API.
class AuthNotifier extends Notifier<AuthState> {
  final _logger = Logger('AuthNotifier');

  @override
  AuthState build() {
    return const AuthState();
  }

  /// Initialize Whitenoise and Rust backend
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      /// 1. Create data and logs directories
      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/whitenoise/data';
      final logsDir = '${dir.path}/whitenoise/logs';

      await Directory(dataDir).create(recursive: true);
      await Directory(logsDir).create(recursive: true);

      /// 2. Create config and initialize Whitenoise instance
      final config = await createWhitenoiseConfig(
        dataDir: dataDir,
        logsDir: logsDir,
      );
      await initializeWhitenoise(config: config);

      /// 3. Auto-login if an account is already active
      try {
        final accountsNotifier = ref.read(accountsProvider.notifier);
        await accountsNotifier.loadAccounts();
        final accounts = await accountsNotifier.readAccounts();
        if (accounts.isNotEmpty) {
          final activeAccount = await accountsNotifier.readActiveAccount();
          final activeAccountPubkey = activeAccount?.pubkey;

          _logger.info('Stored active pubkey: $activeAccountPubkey');

          // Check if stored active account exists in current accounts
          if (activeAccount != null) {
            _logger.info('Found valid stored active account: $activeAccountPubkey');
            state = state.copyWith(isAuthenticated: true);
          } else {
            // No valid stored active account, set the first one as active
            _logger.info(
              'No valid stored active account, setting first account as active: ${accounts.first.pubkey}',
            );
            await accountsNotifier.setActiveAccountPubkey(accounts.first.pubkey);
            state = state.copyWith(isAuthenticated: true);
          }
        } else {
          state = state.copyWith(isAuthenticated: false);
        }
      } catch (e) {
        _logger.warning('Error during auto-login check: $e');
        // If there's an error fetching accounts, assume not authenticated
        state = state.copyWith(isAuthenticated: false);
      }
    } catch (e, st) {
      _logger.severe('initialize', e, st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Create a new account and set it as active
  Future<void> createAccount() async {
    if (!state.isAuthenticated) {
      await initialize();
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await ref.read(accountsProvider.notifier).createAccount();
      state = state.copyWith(isAuthenticated: true);

      // Load account data after creating identity
      await ref.read(accountProvider.notifier).loadAccountData();
    } catch (e, st) {
      _logger.severe('createAccount', e, st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Create account in background without showing loading state
  Future<void> createAccountInBackground() async {
    if (!state.isAuthenticated) {
      await initialize();
    }

    state = state.copyWith(error: null);

    try {
      await ref.read(accountsProvider.notifier).createAccount();
      state = state.copyWith(isAuthenticated: true);

      await ref.read(accountProvider.notifier).loadAccountData();
    } catch (e, st) {
      _logger.severe('createAccountInBackground', e, st);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Login with a private key (nsec or hex)
  Future<void> loginWithKey(String nsecOrPrivkey) async {
    if (!state.isAuthenticated) {
      await initialize();
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Save existing accounts (before login)
      List<wn_accounts_api.Account> existingAccounts = [];
      try {
        existingAccounts = await wn_accounts_api.getAccounts();
        _logger.info('Existing accounts before login: ${existingAccounts.length}');
      } catch (e) {
        _logger.info('No existing accounts or error fetching: $e');
      }

      final account = await wn_accounts_api.login(nsecOrHexPrivkey: nsecOrPrivkey);
      _logger.info('Login successful for account: ${account.pubkey}');
      state = state.copyWith(isAuthenticated: true);
      await ref.read(accountsProvider.notifier).setActiveAccountPubkey(account.pubkey);
      _logger.info('Active account set: ${account.pubkey}');
    } catch (e, st) {
      String errorMessage;

      // Check if it's a WhitenoiseError and convert it to a readable message
      if (e is ApiError) {
        try {
          errorMessage = e.message;
          if (errorMessage.contains('InvalidSecretKey')) {
            errorMessage = 'Invalid nsec or private key';
          }
        } catch (conversionError) {
          // Fallback if conversion fails
          errorMessage = 'Invalid nsec or private key';
        }
        // Log the user-friendly error message for WhitenoiseError instead of the raw exception
        _logger.warning('loginWithKey failed: $errorMessage');
      } else {
        errorMessage = e.toString();
        // Log unexpected errors as severe with full stack trace
        _logger.severe('loginWithKey unexpected error', e, st);
      }

      state = state.copyWith(error: errorMessage);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Logout the currently active account (if any)
  Future<void> logoutActiveAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    final accountsNotifier = ref.read(accountsProvider.notifier);

    try {
      final activeAccount = await ref.read(accountsProvider.notifier).readActiveAccount();
      if (activeAccount == null) {
        debugPrint('Auth provider: no active account');
        return;
      } else {
        debugPrint('Auth provider: logout active account');
        await wn_accounts_api.logout(pubkey: activeAccount.pubkey);
        // Clear the active account
        await accountsNotifier.clearActiveAccountPubkey();

        // Check if there are other accounts available
        debugPrint('Auth provider:Loading accounts');
        await accountsNotifier.loadAccounts();
        debugPrint('Accounts loaded');
        final remainingAccounts = await accountsNotifier.readAccounts();
        debugPrint(
          'Remaining accounts npubs are ${remainingAccounts.map((account) => account.pubkey).join(', ')}',
        );
        if (remainingAccounts.isNotEmpty) {
          // Switch to the first available account
          final newActiveAccountPubkey = remainingAccounts.first.pubkey;
          _logger.info('Switching to another account after logout: $newActiveAccountPubkey');
          await accountsNotifier.setActiveAccountPubkey(newActiveAccountPubkey);

          // Keep authenticated state as true since we have another account
          state = state.copyWith(isAuthenticated: true, isLoading: false);
        } else {
          // No other accounts available, set as unauthenticated
          _logger.info('No other accounts available after logout, setting unauthenticated');
          state = state.copyWith(isAuthenticated: false, isLoading: false);
        }
      }
    } catch (e, st) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      _logger.severe('logoutActiveAccount', e, st);
    }
  }

  void setUnAuthenticated() {
    // Only reset auth state, don't clear active account info
    // This preserves the active account when going to login screen
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
