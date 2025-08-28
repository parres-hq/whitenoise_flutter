// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/contacts_provider.dart';
import 'package:whitenoise/routing/router_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;

class AccountState {
  final FlutterMetadata? metadata;
  final String? pubkey;
  final Map<String, Account>? accounts;
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
    Map<String, Account>? accounts,
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
  Future<void> loadAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    if (!ref.read(authProvider).isAuthenticated) {
      state = state.copyWith(
        error: 'Not authenticated',
        isLoading: false,
      );
      return;
    }

    try {
      final activeAccount = await ref.read(activeAccountProvider.future);

      if (activeAccount == null) {
        state = state.copyWith(error: 'No active account found');
      } else {
        final metadata = await fetchMetadataFrom(
          pubkey: activeAccount.pubkey,
          nip65Relays: activeAccount.nip65Relays,
        );

        state = state.copyWith(
          metadata: metadata,
          pubkey: activeAccount.pubkey,
        );

        // Automatically load contacts for the active account
        try {
          await ref.read(contactsProvider.notifier).loadContacts(activeAccount.pubkey);
        } catch (e) {
          _logger.severe('Failed to load contacts: $e');
        }
      }
    } catch (e, st) {
      _logger.severe('loadAccount', e, st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Fetch and store all accounts
  Future<List<Account>?> listAccounts() async {
    try {
      final accountsList = await getAccounts();
      final accountsMap = <String, Account>{};
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
          // Get file extension to determine image type
          final fileExtension = path.extension(profilePicPath);
          final imageType = await imageTypeFromExtension(extension_: fileExtension);

          final activeAccount = await ref.read(activeAccountProvider.future);
          if (activeAccount == null) {
            ref.showRawErrorToast('No active account found');
            return;
          }

          final serverUrl = await getDefaultBlossomServerUrl();
          profilePictureUrl = await uploadProfilePicture(
            pubkey: activeAccount.pubkey,
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

        await updateMetadata(
          metadata: accountMetadata,
          pubkey: pubkey
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
