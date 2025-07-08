// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/routing/router_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

class AccountState {
  final MetadataData? metadata;
  final String? pubkey;
  final Map<String, AccountData>? accounts;
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
    MetadataData? metadata,
    String? pubkey,
    Map<String, AccountData>? accounts,
    bool? isLoading,
    String? error,
    String? selectedImagePath,
  }) => AccountState(
    metadata: metadata ?? this.metadata,
    pubkey: pubkey ?? this.pubkey,
    accounts: accounts ?? this.accounts,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    selectedImagePath: selectedImagePath ?? this.selectedImagePath,
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
          metadata: metadata,
          pubkey: activeAccountData.pubkey,
        );

        // Automatically load contacts for the active account
        try {
          await ref.read(contactsProvider.notifier).loadContacts(activeAccountData.pubkey);
        } catch (e) {
          _logger.severe('Failed to load contacts: $e');
        }
      }
    } catch (e, st) {
      _logger.severe('loadAccountData', e, st);
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
      _logger.severe('listAccounts', e, st);
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // Set a specific account as active
  Future<void> setActiveAccount(Account account) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await convertAccountToData(account: account);
      state = state.copyWith(pubkey: data.pubkey);

      // Automatically load contacts for the newly active account
      try {
        await ref.read(contactsProvider.notifier).loadContacts(data.pubkey);
      } catch (e) {
        _logger.severe('Failed to load contacts: $e');
      }
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
          return;
        }

        if (profilePicPath != null) {
          // Get file extension to determine image type
          final fileExtension = path.extension(profilePicPath);
          final imageType = await imageTypeFromExtension(extension_: fileExtension);

          final activeAccount =
              await ref.read(activeAccountProvider.notifier).getActiveAccountData();
          if (activeAccount == null) {
            ref.showRawErrorToast('No active account found');
            return;
          }

          final serverUrl = await getDefaultBlossomServerUrl();
          final publicKey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);

          profilePictureUrl = await uploadProfilePicture(
            pubkey: publicKey,
            serverUrl: serverUrl,
            filePath: profilePicPath,
            imageType: imageType,
          );
        }

        if (isDisplayNameChanged) {
          accountMetadata.displayName = displayName;
        }

        if (isBioProvided) {
          accountMetadata.about = bio;
        }

        if (profilePictureUrl != null) {
          accountMetadata.picture = profilePictureUrl;
        }

        final publicKey = await publicKeyFromString(publicKeyString: pubkey);

        await updateMetadata(
          metadata: accountMetadata,
          pubkey: publicKey,
        );
        ref.read(routerProvider).go('/chats');
      }
    } catch (e, st) {
      _logger.severe('updateMetadata', e, st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
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
