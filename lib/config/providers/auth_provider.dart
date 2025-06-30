import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/config/providers/account_provider.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/states/auth_state.dart';
import 'package:whitenoise/src/rust/api.dart';

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
        final accounts = await fetchAccounts();
        if (accounts.isNotEmpty) {
          // Wait for active account provider to load from storage first
          final activeAccountNotifier = ref.read(activeAccountProvider.notifier);
          await activeAccountNotifier.loadActiveAccount();

          final storedActivePubkey = ref.read(activeAccountProvider);
          _logger.info('Stored active pubkey: $storedActivePubkey');

          // Check if stored active account exists in current accounts
          if (storedActivePubkey != null &&
              accounts.any((account) => account.pubkey == storedActivePubkey)) {
            _logger.info('Found valid stored active account: $storedActivePubkey');
            state = state.copyWith(isAuthenticated: true);
          } else {
            // No valid stored active account, set the first one as active
            _logger.info(
              'No valid stored active account, setting first account as active: ${accounts.first.pubkey}',
            );
            await activeAccountNotifier.setActiveAccount(accounts.first.pubkey);
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

      // Account created successfully

      // Get the newly created account data and set it as active
      final accountData = await convertAccountToData(account: account);
      await ref.read(activeAccountProvider.notifier).setActiveAccount(accountData.pubkey);

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

  /// Login with a private key (nsec or hex)
  Future<void> loginWithKey(String nsecOrPrivkey) async {
    if (!state.isAuthenticated) {
      await initialize();
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      /// 1. Perform login using Rust API
      final account = await login(nsecOrHexPrivkey: nsecOrPrivkey);

      // Account logged in successfully

      // Get the logged in account data and set it as active
      final accountData = await convertAccountToData(account: account);
      await ref.read(activeAccountProvider.notifier).setActiveAccount(accountData.pubkey);

      state = state.copyWith(isAuthenticated: true);

      // Load account data after login
      await ref.read(accountProvider.notifier).loadAccountData();
    } catch (e, st) {
      String errorMessage;

      // Check if it's a WhitenoiseError and convert it to a readable message
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
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

  /// Get the currently active account (if any)
  Future<Account?> getCurrentActiveAccount() async {
    if (!state.isAuthenticated) {
      return null;
    }
    try {
      // Try to get accounts and find the first one (active account)
      final accounts = await fetchAccounts();
      if (accounts.isNotEmpty) {
        // Return the first account as the active one
        // In a real implementation, you might want to store which account is active
        // We need to create an Account object from AccountData
        // For now, we'll use a workaround - we need to get the actual Account object
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
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData != null) {
        final publicKey = await publicKeyFromString(
          publicKeyString: activeAccountData.pubkey,
        );
        await logout(pubkey: publicKey);

        // Clear the active account
        await ref.read(activeAccountProvider.notifier).clearActiveAccount();
      }
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
      _logger.severe('logoutCurrentAccount', e, st);
    } finally {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
