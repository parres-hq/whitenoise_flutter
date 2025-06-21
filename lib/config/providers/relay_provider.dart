import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
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
      if (authState.whitenoise == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Whitenoise not initialized',
        );
        return;
      }

      final account = await getActiveAccount(whitenoise: authState.whitenoise!);
      if (account == null) {
        state = state.copyWith(isLoading: false, error: 'No active account');
        return;
      }

      final npub = await exportAccountNpub(
        whitenoise: authState.whitenoise!,
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeNostr();

      final relayUrls = await fetchRelays(
        whitenoise: authState.whitenoise!,
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
      final authState = ref.read(authProvider);
      final account = await getActiveAccount(whitenoise: authState.whitenoise!);
      if (account == null) return;

      final relayUrl = await relayUrlFromString(url: url);
      final npub = await exportAccountNpub(
        whitenoise: authState.whitenoise!,
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeNostr();

      final currentRelayUrls = await fetchRelays(
        whitenoise: authState.whitenoise!,
        pubkey: publicKey,
        relayType: relayType,
      );

      await updateRelays(
        whitenoise: authState.whitenoise!,
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
      if (authState.whitenoise == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Whitenoise not initialized',
        );
        return;
      }

      final account = await getActiveAccount(whitenoise: authState.whitenoise!);
      if (account == null) {
        state = state.copyWith(isLoading: false, error: 'No active account');
        return;
      }

      final npub = await exportAccountNpub(
        whitenoise: authState.whitenoise!,
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeInbox();

      final relayUrls = await fetchRelays(
        whitenoise: authState.whitenoise!,
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
      final authState = ref.read(authProvider);
      final account = await getActiveAccount(whitenoise: authState.whitenoise!);
      if (account == null) return;

      final relayUrl = await relayUrlFromString(url: url);
      final npub = await exportAccountNpub(
        whitenoise: authState.whitenoise!,
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeInbox();

      final currentRelayUrls = await fetchRelays(
        whitenoise: authState.whitenoise!,
        pubkey: publicKey,
        relayType: relayType,
      );

      await updateRelays(
        whitenoise: authState.whitenoise!,
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
      if (authState.whitenoise == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Whitenoise not initialized',
        );
        return;
      }

      final account = await getActiveAccount(whitenoise: authState.whitenoise!);
      if (account == null) {
        state = state.copyWith(isLoading: false, error: 'No active account');
        return;
      }

      final npub = await exportAccountNpub(
        whitenoise: authState.whitenoise!,
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeKeyPackage();

      final relayUrls = await fetchRelays(
        whitenoise: authState.whitenoise!,
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
      final authState = ref.read(authProvider);
      final account = await getActiveAccount(whitenoise: authState.whitenoise!);
      if (account == null) return;

      final relayUrl = await relayUrlFromString(url: url);
      final npub = await exportAccountNpub(
        whitenoise: authState.whitenoise!,
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final relayType = await relayTypeKeyPackage();

      final currentRelayUrls = await fetchRelays(
        whitenoise: authState.whitenoise!,
        pubkey: publicKey,
        relayType: relayType,
      );

      await updateRelays(
        whitenoise: authState.whitenoise!,
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
