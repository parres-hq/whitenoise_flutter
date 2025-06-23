import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/src/rust/api.dart';

class ContactsState {
  final Map<PublicKey, MetadataData?>? contacts;
  final bool isLoading;
  final String? error;

  const ContactsState({this.contacts, this.isLoading = false, this.error});

  ContactsState copyWith({
    Map<PublicKey, MetadataData?>? contacts,
    bool? isLoading,
    String? error,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ContactsNotifier extends Notifier<ContactsState> {
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

      // fetchContacts already returns Map<PublicKey, MetadataData?> with metadata included
      debugPrint('ContactsProvider: Loaded ${raw.length} contacts');
      for (final entry in raw.entries) {
        final metadata = entry.value;
        if (metadata != null) {
          debugPrint(
            'ContactsProvider: Contact with metadata - name: ${metadata.name}, displayName: ${metadata.displayName}, picture: ${metadata.picture}',
          );
        } else {
          debugPrint('ContactsProvider: Contact with NULL metadata');
        }
      }

      state = state.copyWith(contacts: raw);
    } catch (e, st) {
      debugPrintStack(label: 'loadContacts', stackTrace: st);
      state = state.copyWith(error: e.toString());
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

      debugPrint('ContactsProvider: Adding contact with key: ${contactKey.trim()}');
      await addContact(pubkey: ownerPubkey, contactPubkey: contactPk);
      debugPrint('ContactsProvider: Contact added successfully, checking metadata...');

      // Try to fetch metadata for the newly added contact
      try {
        final metadata = await fetchMetadata(pubkey: contactPk);
        if (metadata != null) {
          debugPrint(
            'ContactsProvider: Metadata found for new contact - name: ${metadata.name}, displayName: ${metadata.displayName}',
          );
        } else {
          debugPrint('ContactsProvider: No metadata found for new contact');
        }
      } catch (e) {
        debugPrint('ContactsProvider: Error fetching metadata for new contact: $e');
      }

      // Refresh the complete list to get updated contacts with metadata
      await loadContacts(activeAccountData.pubkey);
      debugPrint('ContactsProvider: Contact list refreshed after adding');
    } catch (e, st) {
      debugPrintStack(label: 'addContact', stackTrace: st);
      state = state.copyWith(error: e.toString());
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
      debugPrintStack(label: 'removeContact', stackTrace: st);
      state = state.copyWith(error: e.toString());
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
      debugPrintStack(label: 'replaceContacts', stackTrace: st);
      state = state.copyWith(error: e.toString());
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
      debugPrintStack(label: 'removeContactByPublicKey', stackTrace: st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Riverpod provider
final contactsProvider = NotifierProvider<ContactsNotifier, ContactsState>(
  ContactsNotifier.new,
);
