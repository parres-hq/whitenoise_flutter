import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/src/rust/api.dart';
class ContactsState {
  final Map<String, Metadata?>? contacts;
  final bool isLoading;
  final String? error;

  const ContactsState({
    this.contacts,
    this.isLoading = false,
    this.error,
  });

  ContactsState copyWith({
    Map<String, Metadata?>? contacts,
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

  // Helper to get Whitenoise instance from AuthProvider
  Future<Whitenoise?> _wn() async {
    final wn = ref.read(authProvider).whitenoise;
    if (wn == null) {
      state = state.copyWith(error: 'Whitenoise instance not found');
    }
    return wn;
  }

  // Fetch contacts for a given public key (hex string)
  Future<void> loadContacts(String ownerHex) async {
    state = state.copyWith(isLoading: true, error: null);

    final wn = await _wn();
    if (wn == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final ownerPk = await publicKeyFromString(publicKeyString: ownerHex);
      final raw = await fetchContacts(whitenoise: wn, pubkey: ownerPk);

      // Convert PublicKey to hex string for map keys
      final mapped = <String, Metadata?>{};
      raw.forEach((k, v) => mapped[k.toString()] = v);

      state = state.copyWith(contacts: mapped);
    } catch (e, st) {
      debugPrintStack(label: 'loadContacts', stackTrace: st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Add a new contact (by hex public key) to the active account
  Future<void> addContactByHex(String contactHex) async {
    state = state.copyWith(isLoading: true, error: null);

    final wn = await _wn();
    if (wn == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final acct = await getActiveAccount(whitenoise: wn);
      if (acct == null) {
        state = state.copyWith(error: 'No active account');
        return;
      }

      final contactPk = await publicKeyFromString(publicKeyString: contactHex);
      await addContact(whitenoise: wn, account: acct, contactPubkey: contactPk);

      // Refresh the list
      final acctData = await getAccountData(account: acct);
      await loadContacts(acctData.pubkey);
    } catch (e, st) {
      debugPrintStack(label: 'addContact', stackTrace: st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Remove a contact (by hex public key)
  Future<void> removeContactByHex(String contactHex) async {
    state = state.copyWith(isLoading: true, error: null);

    final wn = await _wn();
    if (wn == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final acct = await getActiveAccount(whitenoise: wn);
      if (acct == null) {
        state = state.copyWith(error: 'No active account');
        return;
      }

      final contactPk = await publicKeyFromString(publicKeyString: contactHex);
      await removeContact(
        whitenoise: wn,
        account: acct,
        contactPubkey: contactPk,
      );

      // Refresh the list
      final acctData = await getAccountData(account: acct);
      await loadContacts(acctData.pubkey);
    } catch (e, st) {
      debugPrintStack(label: 'removeContact', stackTrace: st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Replace the entire contact list (takes a list of hex strings)
  Future<void> replaceContacts(List<String> hexList) async {
    state = state.copyWith(isLoading: true, error: null);

    final wn = await _wn();
    if (wn == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final acct = await getActiveAccount(whitenoise: wn);
      if (acct == null) {
        state = state.copyWith(error: 'No active account');
        return;
      }

      final pkList = <PublicKey>[];
      for (final hex in hexList) {
        pkList.add(await publicKeyFromString(publicKeyString: hex));
      }

      await updateContacts(
        whitenoise: wn,
        account: acct,
        contactPubkeys: pkList,
      );

      // Refresh the list
      final acctData = await getAccountData(account: acct);
      await loadContacts(acctData.pubkey);
    } catch (e, st) {
      debugPrintStack(label: 'replaceContacts', stackTrace: st);
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
