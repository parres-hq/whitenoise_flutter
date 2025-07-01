// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api.dart';

class ContactsState {
  final Map<PublicKey, MetadataData?>? contacts;
  final List<ContactModel>? contactModels;
  final Map<String, PublicKey>? publicKeyMap;
  final bool isLoading;
  final String? error;

  const ContactsState({
    this.contacts,
    this.contactModels,
    this.publicKeyMap,
    this.isLoading = false,
    this.error,
  });

  ContactsState copyWith({
    Map<PublicKey, MetadataData?>? contacts,
    List<ContactModel>? contactModels,
    Map<String, PublicKey>? publicKeyMap,
    bool? isLoading,
    String? error,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      contactModels: contactModels ?? this.contactModels,
      publicKeyMap: publicKeyMap ?? this.publicKeyMap,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ContactsNotifier extends Notifier<ContactsState> {
  final _logger = Logger('ContactsNotifier');

  @override
  ContactsState build() => const ContactsState();

  // Helper to check if auth is available
  bool _isAuthAvailable() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return false;
    }
    return true;
  }

  // Fetch contacts for a given public key (hex string)
  Future<void> loadContacts(String ownerHex) async {
    state = state.copyWith(isLoading: true);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final ownerPk = await publicKeyFromString(publicKeyString: ownerHex);
      final raw = await fetchContacts(pubkey: ownerPk);

      _logger.info('ContactsProvider: Loaded ${raw.length} contacts');

      final contactModels = <ContactModel>[];
      final publicKeyMap = <String, PublicKey>{};

      for (final entry in raw.entries) {
        final metadata = entry.value;

        String? contactIdentifier;
        bool npubSuccess = false;
        try {
          contactIdentifier = await npubFromPublicKey(publicKey: entry.key);
          npubSuccess = true;
          _logger.info('ContactsProvider: ✅ Direct npub conversion successful: $contactIdentifier');
        } catch (e, st) {
          _logger.warning('ContactsProvider: ❌ Direct exportAccountNpub failed: $e \n$st');
        }
        if (!npubSuccess) {
          _logger.severe(
            'ContactsProvider: 💥 ALL npub attempts failed, using fallback: $contactIdentifier',
          );
          _logger.severe(
            'ContactsProvider: PublicKey type: ${entry.key.runtimeType}, hash: ${entry.key.hashCode}',
          );
        }

        // Create the contact model with the resolved identifier
        final contactModel = ContactModel.fromMetadata(
          publicKey: contactIdentifier ?? 'unknown',
          metadata: metadata,
        );

        publicKeyMap[contactIdentifier!] = entry.key;
        contactModels.add(contactModel);

        if (metadata != null) {
          _logger.info(
            'ContactsProvider: Contact processed - name: ${contactModel.name}, displayName: ${contactModel.displayName}, id: $contactIdentifier',
          );
        } else {
          _logger.info(
            'ContactsProvider: Contact processed with NULL metadata - name: ${contactModel.name}, id: $contactIdentifier',
          );
        }
      }

      state = state.copyWith(
        contacts: raw,
        contactModels: contactModels,
        publicKeyMap: publicKeyMap,
      );
    } catch (e, st) {
      _logger.severe('loadContacts', e, st);
      String errorMessage = 'Failed to load contacts';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to load contacts due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Add a new contact (by hex or npub public key) to the active account
  Future<void> addContactByHex(String contactKey) async {
    state = state.copyWith(isLoading: true);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // Get the active account data
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      // Convert pubkey string to PublicKey object
      final ownerPubkey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final contactPk = await publicKeyFromString(publicKeyString: contactKey.trim());

      _logger.info('ContactsProvider: Adding contact with key: ${contactKey.trim()}');
      await addContact(pubkey: ownerPubkey, contactPubkey: contactPk);
      _logger.info('ContactsProvider: Contact added successfully, checking metadata...');

      // Try to fetch metadata for the newly added contact
      try {
        // Create a fresh PublicKey object to avoid disposal issues
        final contactPkForMetadata = await publicKeyFromString(publicKeyString: contactKey.trim());
        final metadata = await fetchMetadata(pubkey: contactPkForMetadata);
        if (metadata != null) {
          _logger.info(
            'ContactsProvider: Metadata found for new contact - name: ${metadata.name}, displayName: ${metadata.displayName}',
          );
        } else {
          _logger.info('ContactsProvider: No metadata found for new contact');
        }
      } catch (e) {
        _logger.severe('ContactsProvider: Error fetching metadata for new contact: $e');
      }

      // Refresh the complete list to get updated contacts with metadata
      await loadContacts(activeAccountData.pubkey);
      _logger.info('ContactsProvider: Contact list refreshed after adding');
    } catch (e, st) {
      _logger.severe('addContact', e, st);
      String errorMessage = 'Failed to add contact';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to add contact due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Remove a contact (by hex or npub public key)
  Future<void> removeContactByHex(String contactKey) async {
    state = state.copyWith(isLoading: true);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // Get the active account data
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      // Convert pubkey strings to PublicKey objects
      final ownerPubkey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final contactPk = await publicKeyFromString(publicKeyString: contactKey.trim());

      await removeContact(
        pubkey: ownerPubkey,
        contactPubkey: contactPk,
      );

      // Refresh the list
      await loadContacts(activeAccountData.pubkey);
    } catch (e, st) {
      _logger.severe('removeContact', e, st);
      String errorMessage = 'Failed to remove contact';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to remove contact due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Replace the entire contact list (takes a list of hex strings)
  Future<void> replaceContacts(List<String> hexList) async {
    state = state.copyWith(isLoading: true);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // Get the active account data
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      // Convert pubkey string to PublicKey object
      final ownerPubkey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);

      final pkList = <PublicKey>[];
      for (final hex in hexList) {
        pkList.add(await publicKeyFromString(publicKeyString: hex));
      }

      await updateContacts(
        pubkey: ownerPubkey,
        contactPubkeys: pkList,
      );

      // Refresh the list
      await loadContacts(activeAccountData.pubkey);
    } catch (e, st) {
      _logger.severe('replaceContacts', e, st);
      String errorMessage = 'Failed to update contacts';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to update contacts due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Remove a contact directly from the current state (for UI operations)
  void removeContactFromState(PublicKey publicKey) {
    final currentContacts = state.contacts;
    if (currentContacts != null) {
      final updatedContacts = Map<PublicKey, MetadataData?>.from(currentContacts);
      updatedContacts.remove(publicKey);
      state = state.copyWith(contacts: updatedContacts);
    }
  }

  // Remove a contact using PublicKey (calls Rust API directly)
  Future<void> removeContactByPublicKey(PublicKey publicKey) async {
    state = state.copyWith(isLoading: true);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // Get the active account data
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return;
      }

      // Convert pubkey string to PublicKey object
      final ownerPubkey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);

      await removeContact(
        pubkey: ownerPubkey,
        contactPubkey: publicKey,
      );

      // Refresh the list
      await loadContacts(activeAccountData.pubkey);
    } catch (e, st) {
      _logger.severe('removeContactByPublicKey', e, st);
      String errorMessage = 'Failed to remove contact';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to remove contact due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Helper methods for UI components
  List<ContactModel> getFilteredContacts(String searchQuery) {
    final contacts = state.contactModels;
    if (contacts == null) return [];

    if (searchQuery.isEmpty) return contacts;

    return contacts
        .where(
          (contact) =>
              contact.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              contact.displayNameOrName.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              (contact.nip05?.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              contact.publicKey.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  PublicKey? getPublicKeyForContact(String contactPublicKey) {
    return state.publicKeyMap?[contactPublicKey];
  }

  List<ContactModel> get allContacts => state.contactModels ?? [];
}

// Riverpod provider
final contactsProvider = NotifierProvider<ContactsNotifier, ContactsState>(
  ContactsNotifier.new,
);
