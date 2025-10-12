import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/avatar_color_provider.dart';
import 'package:whitenoise/config/states/auth_state.dart';
import 'package:whitenoise/src/rust/api.dart' show createWhitenoiseConfig, initializeWhitenoise;
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/error.dart' show ApiError;
import 'package:whitenoise/utils/pubkey_formatter.dart';

/// Auth Provider
///
/// This provider manages authentication.
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
        final accounts = await getAccounts();
        if (accounts.isNotEmpty) {
          // Wait for active account provider to load from storage first
          final activePubkeyNotifier = ref.read(activePubkeyProvider.notifier);
          await activePubkeyNotifier.loadActivePubkey();

          final storedActivePubkey = ref.read(activePubkeyProvider) ?? '';
          _logger.info('Stored active pubkey: $storedActivePubkey');

          // Check if stored active account exists in current accounts
          if (storedActivePubkey.isNotEmpty &&
              accounts.any((account) => account.pubkey == storedActivePubkey)) {
            _logger.info('Found valid stored active account: $storedActivePubkey');
            state = state.copyWith(isAuthenticated: true);
          } else {
            // No valid stored active account, set the first one as active
            _logger.info(
              'No valid stored active account, setting first account as active: ${accounts.first.pubkey}',
            );
            await activePubkeyNotifier.setActivePubkey(accounts.first.pubkey);
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
      final account = await createIdentity();

      await ref.read(avatarColorProvider.notifier).getColor(account.pubkey);

      // Get the newly created account data and set it as active

      await ref.read(activePubkeyProvider.notifier).setActivePubkey(account.pubkey);

      state = state.copyWith(isAuthenticated: true);

      await ref.read(activeAccountProvider.future);
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
      final account = await createIdentity();

      await ref.read(avatarColorProvider.notifier).getColor(account.pubkey);

      // Get the newly created account data and set it as active
      await ref.read(activePubkeyProvider.notifier).setActivePubkey(account.pubkey);

      state = state.copyWith(isAuthenticated: true);

      await ref.read(activeAccountProvider.future);
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
      List<Account> existingAccounts = [];
      try {
        existingAccounts = await getAccounts();
        _logger.info('Existing accounts before login: ${existingAccounts.length}');
      } catch (e) {
        _logger.info('No existing accounts or error fetching: $e');
      }

      /// 1. Perform login using Rust API
      final account = await login(nsecOrHexPrivkey: nsecOrPrivkey);
      _logger.info('Login successful, account created');

      await ref.read(avatarColorProvider.notifier).getColor(account.pubkey);

      // Get the logged in account data and set it as active

      _logger.info('Converting account to data: ${account.pubkey}');

      // Set authenticated state first
      state = state.copyWith(isAuthenticated: true);

      // Then set the active account
      await ref.read(activePubkeyProvider.notifier).setActivePubkey(account.pubkey);
      _logger.info('Set active account: ${account.pubkey}');

      await ref.read(activeAccountProvider.future);
      _logger.info('Account data loaded');

      // Check account count after login
      try {
        final accountsAfterLogin = await getAccounts();
        _logger.info('Accounts after login: ${accountsAfterLogin.length}');

        // Check that the active account is set correctly
        final currentActivePubkey = ref.read(activePubkeyProvider);
        _logger.info('Current active account after login: $currentActivePubkey');

        // Warn if previous accounts have been lost
        if (existingAccounts.isNotEmpty &&
            accountsAfterLogin.length < existingAccounts.length + 1) {
          _logger.warning('Some existing accounts may have been lost during login');
        }
      } catch (e) {
        _logger.warning('Error checking accounts after login: $e');
      }
    } catch (e, st) {
      String errorMessage;

      // Check if it's a Whitenoise ApiError and convert it to a readable message
      if (e is ApiError) {
        errorMessage = await e.messageText();
        if (await e.errorType() == 'InvalidSecretKey') {
          errorMessage = 'Invalid nsec or private key';
        }
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

  /// Login with a private key in background without showing loading state
  Future<void> loginWithKeyInBackground(String nsecOrPrivkey) async {
    if (!state.isAuthenticated) {
      await initialize();
    }

    state = state.copyWith(error: null);

    try {
      /// 1. Perform login using Rust API
      final account = await login(nsecOrHexPrivkey: nsecOrPrivkey);

      // Account logged in successfully

      // Get the logged in account data and set it as active

      await ref.read(activePubkeyProvider.notifier).setActivePubkey(account.pubkey);

      state = state.copyWith(isAuthenticated: true);

      await ref.read(activeAccountProvider.future);
    } catch (e, st) {
      String errorMessage;

      // Check if it's a Whitenoise ApiError and convert it to a readable message
      if (e is ApiError) {
        errorMessage = await e.messageText();
        if (await e.errorType() == 'InvalidSecretKey') {
          errorMessage = 'Invalid nsec or private key';
        }
        // Log the user-friendly error message for Whitenoise ApiError instead of the raw exception
        _logger.warning('loginWithKeyInBackground failed: $errorMessage');
      } else {
        errorMessage = e.toString();
        // Log unexpected errors as severe with full stack trace
        _logger.severe('loginWithKeyInBackground unexpected error', e, st);
      }

      state = state.copyWith(error: errorMessage);
    }
  }

  /// Get the currently active account (if any)
  Future<Account?> getCurrentActiveAccount() async {
    if (!state.isAuthenticated) {
      return null;
    }
    try {
      // Try to get accounts and find the first one (active account)
      final accounts = await getAccounts();
      if (accounts.isNotEmpty) {
        // Return the first account as the active one
        // In a real implementation, you might want to store which account is active
        // This is a limitation of the current API design
        return null; // This will be handled by the calling code
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Logout the currently active account (if any)
  Future<void> logoutCurrentAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final activeAccountState = await ref.read(activeAccountProvider.future);
      final activeAccount = activeAccountState.account;
      if (activeAccount != null) {
        await logout(pubkey: activeAccount.pubkey);

        // Clear the active account
        await ref.read(activePubkeyProvider.notifier).clearActivePubkey();

        // Check if there are other accounts available
        final remainingAccounts = await getAccounts();
        // Normalize pubkeys to hex then filter
        final activeHex = PubkeyFormatter(pubkey: activeAccount.pubkey).toHex();
        final otherAccounts = <Account>[];
        for (final account in remainingAccounts) {
          final keyHex = PubkeyFormatter(pubkey: account.pubkey).toHex();
          if (keyHex != activeHex) otherAccounts.add(account);
        }
        if (otherAccounts.isNotEmpty) {
          // Switch to the first available account
          _logger.info('Switching to another account after logout: ${otherAccounts.first.pubkey}');
          await ref.read(activePubkeyProvider.notifier).setActivePubkey(otherAccounts.first.pubkey);

          await ref.read(activeAccountProvider.future);

          // Keep authenticated state as true since we have another account
          state = state.copyWith(isAuthenticated: true, isLoading: false);
        } else {
          // No other accounts available, set as unauthenticated
          _logger.info('No other accounts available after logout, setting unauthenticated');

          // Clear all avatar colors since this is the last account
          try {
            await ref.read(avatarColorProvider.notifier).clearAll();
            _logger.info('Cleared all avatar colors after last account logout');
          } catch (e) {
            _logger.warning('Failed to clear avatar colors: $e');
          }

          state = state.copyWith(isAuthenticated: false, isLoading: false);
        }
      } else {
        // No active account to logout, but check if any accounts exist
        final accounts = await getAccounts();
        if (accounts.isNotEmpty) {
          // Set the first account as active
          await ref.read(activePubkeyProvider.notifier).setActivePubkey(accounts.first.pubkey);
          await ref.read(activeAccountProvider.future);
          state = state.copyWith(isAuthenticated: true, isLoading: false);
        } else {
          state = state.copyWith(isAuthenticated: false, isLoading: false);
        }
      }
    } catch (e, st) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      _logger.severe('logoutCurrentAccount', e, st);
    }
  }

  void setUnAuthenticated() {
    // Only reset auth state, don't clear active account info
    // This preserves the active account when going to login screen
    state = const AuthState();
  }

  void deleteAccountInBackground() async {
    try {
      await logoutCurrentAccount();
    } catch (e, st) {
      _logger.severe('deleteAccountInBackground', e, st);
      state = state.copyWith(error: e.toString());
    } finally {
      setUnAuthenticated();
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
