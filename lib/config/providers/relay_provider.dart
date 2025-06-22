import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/ui/settings/network/widgets/network_section.dart';

// State for relay management
class RelayState {
  final List<RelayInfo> relays;
  final bool isLoading;
  final String? error;

  const RelayState({
    this.relays = const [],
    this.isLoading = false,
    this.error,
  });

  RelayState copyWith({
    List<RelayInfo>? relays,
    bool? isLoading,
    String? error,
  }) {
    return RelayState(
      relays: relays ?? this.relays,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Normal relays notifier
class NormalRelaysNotifier extends Notifier<RelayState> {
  @override
  RelayState build() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadRelays());
    return const RelayState();
  }

  Future<void> loadRelays() async {
    state = state.copyWith(isLoading: true);

    try {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated',
        );
        return;
      }

      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(isLoading: false, error: 'No active account found');
        return;
      }

      // Get the cached Account object from auth provider
      final account = ref.read(authProvider.notifier).getAccountByPubkey(activeAccountData.pubkey);
      if (account == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Account object not found - please login again',
        );
        return;
      }

      final npub = await exportAccountNpub(
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeNostr();

      final relayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      final relayInfos = await Future.wait(
        relayUrls.map((relayUrl) async {
          final url = await getRelayUrlString(relayUrl: relayUrl);
          return RelayInfo(url: url, connected: false);
        }),
      );

      state = state.copyWith(relays: relayInfos, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading relays: $e',
      );
    }
  }

  Future<void> addRelay(String url) async {
    try {
      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        print('RelayProvider: No active account found for loading relays');
        return;
      }

      // We need Account object but only have AccountData - this is a limitation
      // Get the cached Account object from auth provider
      final account = ref.read(authProvider.notifier).getAccountByPubkey(activeAccountData.pubkey);
      if (account == null) {
        state = state.copyWith(error: 'Account object not found - please login again');
        return;
      }

      final relayUrl = await relayUrlFromString(url: url);
      final npub = await exportAccountNpub(
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeNostr();

      final currentRelayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      await updateRelays(
        account: account,
        relayType: relayType,
        relays: [...currentRelayUrls, relayUrl],
      );

      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add relay: $e');
    }
  }
}

// Inbox relays notifier
class InboxRelaysNotifier extends Notifier<RelayState> {
  @override
  RelayState build() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadRelays());
    return const RelayState();
  }

  Future<void> loadRelays() async {
    state = state.copyWith(isLoading: true);

    try {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated',
        );
        return;
      }

      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(isLoading: false, error: 'No active account found');
        return;
      }

      // Get the cached Account object from auth provider
      final account = ref.read(authProvider.notifier).getAccountByPubkey(activeAccountData.pubkey);
      if (account == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Account object not found - please login again',
        );
        return;
      }

      final npub = await exportAccountNpub(
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeInbox();

      final relayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      final relayInfos = await Future.wait(
        relayUrls.map((relayUrl) async {
          final url = await getRelayUrlString(relayUrl: relayUrl);
          return RelayInfo(url: url, connected: false);
        }),
      );

      state = state.copyWith(relays: relayInfos, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading relays: $e',
      );
    }
  }

  Future<void> addRelay(String url) async {
    try {
      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        print('RelayProvider: No active account found for removing relay');
        return;
      }

      // We need Account object but only have AccountData - this is a limitation
      // Get the cached Account object from auth provider
      final account = ref.read(authProvider.notifier).getAccountByPubkey(activeAccountData.pubkey);
      if (account == null) {
        state = state.copyWith(error: 'Account object not found - please login again');
        return;
      }

      final relayUrl = await relayUrlFromString(url: url);
      final npub = await exportAccountNpub(
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeInbox();

      final currentRelayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      await updateRelays(
        account: account,
        relayType: relayType,
        relays: [...currentRelayUrls, relayUrl],
      );

      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add relay: $e');
    }
  }
}

// Key package relays notifier
class KeyPackageRelaysNotifier extends Notifier<RelayState> {
  @override
  RelayState build() {
    WidgetsBinding.instance.addPostFrameCallback((_) => loadRelays());
    return const RelayState();
  }

  Future<void> loadRelays() async {
    state = state.copyWith(isLoading: true);

    try {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated',
        );
        return;
      }

      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(isLoading: false, error: 'No active account found');
        return;
      }

      // Get the cached Account object from auth provider
      final account = ref.read(authProvider.notifier).getAccountByPubkey(activeAccountData.pubkey);
      if (account == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Account object not found - please login again',
        );
        return;
      }

      final npub = await exportAccountNpub(
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeKeyPackage();

      final relayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      final relayInfos = await Future.wait(
        relayUrls.map((relayUrl) async {
          final url = await getRelayUrlString(relayUrl: relayUrl);
          return RelayInfo(url: url, connected: false);
        }),
      );

      state = state.copyWith(relays: relayInfos, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading relays: $e',
      );
    }
  }

  Future<void> addRelay(String url) async {
    try {
      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        print('RelayProvider: No active account found for updating relay');
        return;
      }

      // We need Account object but only have AccountData - this is a limitation
      // Get the cached Account object from auth provider
      final account = ref.read(authProvider.notifier).getAccountByPubkey(activeAccountData.pubkey);
      if (account == null) {
        state = state.copyWith(error: 'Account object not found - please login again');
        return;
      }

      final relayUrl = await relayUrlFromString(url: url);
      final npub = await exportAccountNpub(
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeKeyPackage();

      final currentRelayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      await updateRelays(
        account: account,
        relayType: relayType,
        relays: [...currentRelayUrls, relayUrl],
      );

      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add relay: $e');
    }
  }
}

// Providers
final normalRelaysProvider = NotifierProvider<NormalRelaysNotifier, RelayState>(
  NormalRelaysNotifier.new,
);

final inboxRelaysProvider = NotifierProvider<InboxRelaysNotifier, RelayState>(
  InboxRelaysNotifier.new,
);

final keyPackageRelaysProvider = NotifierProvider<KeyPackageRelaysNotifier, RelayState>(
  KeyPackageRelaysNotifier.new,
);
