// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/contacts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

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
  ContactsState build() {
    // Listen to active account changes and refresh contacts automatically
    ref.listen<String?>(activeAccountProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        // Schedule state changes after the build phase to avoid provider modification errors
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          state = const ContactsState();
          final activeAccountData =
              await ref.read(activeAccountProvider.notifier).getActiveAccountData();
          if (activeAccountData != null) {
            await loadContacts(activeAccountData.pubkey);
          }
        });
      } else if (previous != null && next == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          state = const ContactsState();
        });
      } else if (previous == null && next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final activeAccountData =
              await ref.read(activeAccountProvider.notifier).getActiveAccountData();
          if (activeAccountData != null) {
            await loadContacts(activeAccountData.pubkey);
          }
        });
      }
    });

    return const ContactsState();
  }

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
    state = state.copyWith(isLoading: true, error: null);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final ownerPk = await publicKeyFromString(publicKeyString: ownerHex);
      final raw = await queryContacts(pubkey: ownerPk);

      _logger.info('ContactsProvider: Loaded ${raw.length} raw contacts from nostr database cache');

      // DEBUG: Check if we have duplicate metadata at the raw level
      final rawMetadataValues = <String, List<String>>{};
      for (final entry in raw.entries) {
        final metadata = entry.value;
        if (metadata?.name != null) {
          final name = metadata!.name!;
          final keyHash = entry.key.hashCode.toString();
          rawMetadataValues.putIfAbsent(name, () => []).add('Key$keyHash');
        }
      }

      _logger.info(
        'ContactsProvider: Raw metadata check complete - ${rawMetadataValues.length} unique names found',
      );

      final metadataCache = ref.read(metadataCacheProvider.notifier);

      _logger.info('ContactsProvider: Pre-populating metadata cache from query results...');
      await metadataCache.bulkPopulateFromQueryResults(raw);
      _logger.info('ContactsProvider: Metadata cache pre-population complete');

      final contactModels = <ContactModel>[];
      final publicKeyMap = <String, PublicKey>{};

      final keyConversions = <PublicKey, String>{};
      _logger.info(
        'ContactsProvider: Starting batch key conversions for ${raw.length} contacts...',
      );

      for (final entry in raw.entries) {
        try {
          final npub = await npubFromPublicKey(publicKey: entry.key);
          keyConversions[entry.key] = npub;
          _logger.info('ContactsProvider: ✅ Converted PublicKey to npub: $npub');
        } catch (e) {
          try {
            final hex = await hexPubkeyFromPublicKey(publicKey: entry.key);
            keyConversions[entry.key] = hex;
            _logger.warning('ContactsProvider: ⚠️ Fallback to hex for PublicKey: $hex');
          } catch (hexError) {
            _logger.severe(
              'ContactsProvider: ❌ All conversions failed for PublicKey: ${entry.key.hashCode}',
            );
            continue; // Skip this contact entirely
          }
        }
      }

      _logger.info(
        'ContactsProvider: Successfully converted ${keyConversions.length}/${raw.length} PublicKeys',
      );

      // VALIDATION: Cross-check cache population with original queryContacts data
      _logger.info('ContactsProvider: Validating cache consistency with query results...');
      final cacheValidationErrors = <String>[];

      for (final rawEntry in raw.entries) {
        try {
          final npub = await npubFromPublicKey(publicKey: rawEntry.key);
          final queryMetadata = rawEntry.value;

          // Check if our cache has the right data for this npub
          final cached = await metadataCache.getContactModel(npub);

          // Validate that the cached name matches what we'd expect from raw data
          final expectedName = queryMetadata?.name ?? queryMetadata?.displayName ?? 'Unknown User';
          final actualName = cached.displayNameOrName;

          // Only flag as error if we expected a real name but got Unknown User, or vice versa
          if (queryMetadata != null &&
              actualName == 'Unknown User' &&
              expectedName != 'Unknown User') {
            cacheValidationErrors.add(
              'Cache mismatch for $npub: expected "$expectedName", got "Unknown User" (metadata was lost)',
            );
          } else if (queryMetadata == null && actualName != 'Unknown User') {
            cacheValidationErrors.add(
              'Cache mismatch for $npub: expected "Unknown User", got "$actualName" (unexpected metadata)',
            );
          }
        } catch (e) {
          // Skip validation for this entry if conversion fails
        }
      }

      if (cacheValidationErrors.isNotEmpty) {
        _logger.warning('ContactsProvider: ⚠️ CACHE VALIDATION WARNINGS:');
        for (final error in cacheValidationErrors) {
          _logger.warning('  - $error - continuing with mitigation in place');
        }
      } else {
        _logger.info('ContactsProvider: ✅ Cache validation passed - no inconsistencies detected');
      }

      // Now get contact models from cache (they should mostly be cached due to bulk population)
      _logger.info('ContactsProvider: Fetching contact models from cache...');
      for (final entry in keyConversions.entries) {
        final publicKey = entry.key;
        final stringKey = entry.value;

        try {
          _logger.info('ContactsProvider: Getting cached contact model for key: $stringKey');

          // Get contact model from cache (should be fast due to pre-population)
          final contactModel = await metadataCache.getContactModel(stringKey);

          _logger.info(
            'ContactsProvider: Got contact: ${contactModel.displayNameOrName} (${contactModel.publicKey})',
          );

          // Validate that the contact model has the correct public key
          if (contactModel.publicKey.toLowerCase() != stringKey.toLowerCase()) {
            _logger.warning(
              'ContactsProvider: 🔥 KEY MISMATCH! Expected: $stringKey, Got: ${contactModel.publicKey}',
            );

            // Create a corrected contact model with the right key
            final correctedContact = ContactModel(
              name: contactModel.name,
              displayName: contactModel.displayName,
              publicKey: stringKey, // Use the CORRECT key
              imagePath: contactModel.imagePath,
              about: contactModel.about,
              website: contactModel.website,
              nip05: contactModel.nip05,
              lud16: contactModel.lud16,
            );

            contactModels.add(correctedContact);
            _logger.info(
              'ContactsProvider: ✅ Added CORRECTED contact: ${correctedContact.displayNameOrName} (${correctedContact.publicKey})',
            );
          } else {
            contactModels.add(contactModel);
            _logger.info(
              'ContactsProvider: ✅ Added contact: ${contactModel.displayNameOrName} (${contactModel.publicKey})',
            );
          }

          // Map the string key to the original PublicKey for operations
          publicKeyMap[stringKey] = publicKey;
        } catch (e, st) {
          _logger.severe('ContactsProvider: Failed to get metadata for $stringKey: $e\n$st');

          // Add fallback contact
          final fallbackContact = ContactModel(
            name: 'Unknown User',
            publicKey: stringKey,
          );

          contactModels.add(fallbackContact);
          publicKeyMap[stringKey] = publicKey;

          _logger.info('ContactsProvider: ⚠️ Added fallback contact for: $stringKey');
        }
      }

      // Final validation - check for duplicate display names
      final nameToKeys = <String, List<String>>{};
      for (final contact in contactModels) {
        final name = contact.displayNameOrName;
        nameToKeys.putIfAbsent(name, () => []).add(contact.publicKey);
      }

      for (final entry in nameToKeys.entries) {
        if (entry.value.length > 1 && entry.key != 'Unknown User') {
          _logger.warning(
            'ContactsProvider: 🚨 DUPLICATE NAME DETECTED: "${entry.key}" for keys: ${entry.value} - continuing with mitigation in place',
          );
        }
      }

      // PERFORMANCE: Sort contacts alphabetically by display name (putting Unknown Users at bottom)
      contactModels.sort((a, b) {
        final aName = a.displayNameOrName;
        final bName = b.displayNameOrName;

        // Put "Unknown User" entries at the bottom
        if (aName == 'Unknown User' && bName != 'Unknown User') return 1;
        if (bName == 'Unknown User' && aName != 'Unknown User') return -1;
        if (aName == 'Unknown User' && bName == 'Unknown User') return 0;

        // Normal alphabetical sorting for everything else
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });

      _logger.info(
        'ContactsProvider: ✅ Successfully processed ${contactModels.length} contacts with ${nameToKeys.length} unique names (sorted alphabetically)',
      );

      // Debug: Log all final contacts
      for (int i = 0; i < contactModels.length; i++) {
        final contact = contactModels[i];
        _logger.info(
          'ContactsProvider: Final contact #$i: ${contact.displayNameOrName} -> ${contact.publicKey}',
        );
      }

      state = state.copyWith(
        contacts: raw,
        contactModels: contactModels,
        publicKeyMap: publicKeyMap,
      );
    } catch (e, st) {
      _logger.severe('ContactsProvider: loadContacts failed: $e\n$st');
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
