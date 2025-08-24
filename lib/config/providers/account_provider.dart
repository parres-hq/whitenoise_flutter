// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/routing/router_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as wnAccountsApi;
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/metadata.dart';

class AccountState {
  final FlutterMetadata? metadata;
  final String? pubkey;
  final Map<String, wnAccountsApi.Account>? accounts;
  final bool isLoading;
  final String? error;
  final String? selectedImagePath;

  const AccountState({
    this.metadata,
    this.pubkey,
    this.accounts,
    this.isLoading = false,
    this.error,
    this.selectedImagePath,
  });

  AccountState copyWith({
    FlutterMetadata? metadata,
    String? pubkey,
    Map<String, wnAccountsApi.Account>? accounts,
    bool? isLoading,
    String? error,
    String? selectedImagePath,
    bool clearSelectedImagePath = false,
  }) => AccountState(
    metadata: metadata ?? this.metadata,
    pubkey: pubkey ?? this.pubkey,
    accounts: accounts ?? this.accounts,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    selectedImagePath:
        clearSelectedImagePath ? null : (selectedImagePath ?? this.selectedImagePath),
  );
}

class AccountNotifier extends Notifier<AccountState> {
  final _logger = Logger('AccountNotifier');

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
      final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccount();

      if (activeAccount == null) {
        state = state.copyWith(error: 'No active account found');
      } else {
        final publicKey = activeAccount.pubkey;
        final metadata = await wnAccountsApi.accountMetadata(
          pubkey: publicKey,
        );

        state = state.copyWith(
          metadata: metadata,
          pubkey: activeAccount.pubkey,
        );

        // TODO big plans: load follows?

        // try {
        //   await ref.read(contactsProvider.notifier).loadContacts(activeAccount.pubkey);
        // } catch (e) {
        //   _logger.severe('Failed to load contacts: $e');
        // }
      }
    } catch (e, st) {
      _logger.severe('loadAccountData', e, st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Fetch and store all accounts
  Future<List<wnAccountsApi.Account>?> listAccounts() async {
    try {
      final accountsList = await wnAccountsApi.getAccounts();
      final accountsMap = <String, wnAccountsApi.Account>{};
      for (final account in accountsList) {
        accountsMap[account.pubkey] = account;
      }
      state = state.copyWith(accounts: accountsMap);
      return accountsList;
    } catch (e, st) {
      _logger.severe('listAccounts', e, st);
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Set a specific account as active
  Future<void> setActiveAccount(wnAccountsApi.Account account) async {
    state = state.copyWith(isLoading: true);
    try {
      state = state.copyWith(pubkey: account.pubkey);

      // TODO big plans: reload follows?
      // try {
      //   await ref.read(contactsProvider.notifier).loadContacts(account.pubkey);
      // } catch (e) {
      //   _logger.severe('Failed to load contacts: $e');
      // }
    } catch (e, st) {
      _logger.severe('setActiveAccount', e, st);
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
  Future<void> updateAccountMetadata(WidgetRef ref, String displayName, String bio) async {
    if (displayName.isEmpty) {
      ref.showRawErrorToast('Please enter a name');
      return;
    }

    String? profilePictureUrl;
    state = state.copyWith(isLoading: true, error: null);
    final profilePicPath = state.selectedImagePath;

    try {
      final accountMetadata = state.metadata;
      final pubkey = state.pubkey;

      if (accountMetadata != null && pubkey != null) {
        final isDisplayNameChanged =
            displayName.isNotEmpty && displayName != accountMetadata.displayName;
        final isBioProvided = bio.isNotEmpty;

        // Skipping update if there's nothing to change
        if (!isDisplayNameChanged && !isBioProvided && profilePicPath == null) {
          ref.read(routerProvider).go('/chats');
          return;
        }

        if (profilePicPath != null) {
          final imageType = path.extension(profilePicPath);

          final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccount();
          if (activeAccount == null) {
            ref.showRawErrorToast('No active account found');
            return;
          }

          final serverUrl = await getDefaultBlossomServerUrl();
          final publicKey = activeAccount.pubkey;

          profilePictureUrl = await wnAccountsApi.uploadAccountProfilePicture(
            pubkey: publicKey,
            serverUrl: serverUrl,
            filePath: profilePicPath,
            imageType: imageType,
          );
        }

        // TODO big plans: update metadata
        final newDisplayName = isDisplayNameChanged ? displayName : accountMetadata.displayName;
        final newAbout = isBioProvided ? bio : accountMetadata.about;
        final newPicture = profilePictureUrl ?? accountMetadata.picture;

        await wnAccountsApi.updateAccountMetadata(
          metadata: accountMetadata, // replace with new metadata object with new values
          pubkey: pubkey,
        );
        ref.read(routerProvider).go('/chats');
      }
    } catch (e, st) {
      _logger.severe('updateMetadata', e, st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false, clearSelectedImagePath: true);
    }
  }

  Future<void> pickProfileImage(WidgetRef ref) async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(selectedImagePath: image.path);
      }
    } catch (e) {
      ref.showRawErrorToast('Failed to pick image: $e');
    }
  }
}

final accountProvider = NotifierProvider<AccountNotifier, AccountState>(
  AccountNotifier.new,
);
