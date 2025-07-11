import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/relay_status_provider.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
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
  final _logger = Logger('NormalRelaysNotifier');

  @override
  RelayState build() {
    Future.microtask(() => loadRelays());
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

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayType = await relayTypeNostr();

      final relayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      // Ensure relay status provider is loaded first
      final statusState = ref.read(relayStatusProvider);
      if (statusState.relayStatuses.isEmpty && !statusState.isLoading) {
        await ref.read(relayStatusProvider.notifier).loadRelayStatuses();
      }

      final relayInfos = await Future.wait(
        relayUrls.map((relayUrl) async {
          final url = await stringFromRelayUrl(relayUrl: relayUrl);
          // Get status from relay status provider
          final statusNotifier = ref.read(relayStatusProvider.notifier);
          final status = statusNotifier.getRelayStatus(url);
          final connected = statusNotifier.isRelayConnected(url);
          return RelayInfo(url: url, connected: connected, status: status);
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
        _logger.severe('RelayProvider: No active account found for adding relay');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayUrl = await relayUrlFromString(url: url);
      final relayType = await relayTypeNostr();

      final currentRelayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      final refreshedPublicKey = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      final refreshedRelayType = await relayTypeNostr();

      await updateRelays(
        pubkey: refreshedPublicKey,
        relayType: refreshedRelayType,
        relays: [...currentRelayUrls, relayUrl],
      );

      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add relay: $e');
    }
  }

  Future<void> deleteRelay(String url) async {
    try {
      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        _logger.severe('RelayProvider: No active account found for deleting relay');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayType = await relayTypeNostr();

      final currentRelayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      // Filter out the relay to delete
      final List<RelayUrl> updatedRelayUrls = [];
      for (final relayUrl in currentRelayUrls) {
        final urlString = await stringFromRelayUrl(relayUrl: relayUrl);
        if (urlString != url) {
          updatedRelayUrls.add(relayUrl);
        }
      }
      final refreshedPublicKey = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      final refreshedRelayType = await relayTypeNostr();
      await updateRelays(
        pubkey: refreshedPublicKey,
        relayType: refreshedRelayType,
        relays: updatedRelayUrls,
      );

      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete relay: $e');
    }
  }
}

// Inbox relays notifier
class InboxRelaysNotifier extends Notifier<RelayState> {
  final _logger = Logger('InboxRelaysNotifier');

  @override
  RelayState build() {
    Future.microtask(() => loadRelays());
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

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayType = await relayTypeInbox();

      final relayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      // Ensure relay status provider is loaded first
      final statusState = ref.read(relayStatusProvider);
      if (statusState.relayStatuses.isEmpty && !statusState.isLoading) {
        await ref.read(relayStatusProvider.notifier).loadRelayStatuses();
      }

      final relayInfos = await Future.wait(
        relayUrls.map((relayUrl) async {
          final url = await stringFromRelayUrl(relayUrl: relayUrl);
          // Get status from relay status provider
          final statusNotifier = ref.read(relayStatusProvider.notifier);
          final status = statusNotifier.getRelayStatus(url);
          final connected = statusNotifier.isRelayConnected(url);
          return RelayInfo(url: url, connected: connected, status: status);
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
        _logger.severe('RelayProvider: No active account found for adding relay');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayUrl = await relayUrlFromString(url: url);
      final relayType = await relayTypeInbox();

      final currentRelayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      final refreshedPublicKey = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      final refreshedRelayType = await relayTypeInbox();

      await updateRelays(
        pubkey: refreshedPublicKey,
        relayType: refreshedRelayType,
        relays: [...currentRelayUrls, relayUrl],
      );

      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add relay: $e');
    }
  }

  Future<void> deleteRelay(String url) async {
    try {
      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        _logger.severe('RelayProvider: No active account found for deleting relay');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayType = await relayTypeInbox();

      final currentRelayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      // Filter out the relay to delete
      final List<RelayUrl> updatedRelayUrls = [];
      for (final relayUrl in currentRelayUrls) {
        final urlString = await stringFromRelayUrl(relayUrl: relayUrl);
        if (urlString != url) {
          updatedRelayUrls.add(relayUrl);
        }
      }
      final refreshedPublicKey = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      final refreshedRelayType = await relayTypeInbox();
      await updateRelays(
        pubkey: refreshedPublicKey,
        relayType: refreshedRelayType,
        relays: updatedRelayUrls,
      );

      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete relay: $e');
    }
  }
}

// Key package relays notifier
class KeyPackageRelaysNotifier extends Notifier<RelayState> {
  final _logger = Logger('KeyPackageRelaysNotifier');

  @override
  RelayState build() {
    Future.microtask(() => loadRelays());
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

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayType = await relayTypeKeyPackage();

      final relayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      final relayInfos = await Future.wait(
        relayUrls.map((relayUrl) async {
          final url = await stringFromRelayUrl(relayUrl: relayUrl);
          // Get status from relay status provider
          final statusNotifier = ref.read(relayStatusProvider.notifier);
          final status = statusNotifier.getRelayStatus(url);
          final connected = statusNotifier.isRelayConnected(url);
          return RelayInfo(url: url, connected: connected, status: status);
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
        _logger.severe('RelayProvider: No active account found for adding relay');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayUrl = await relayUrlFromString(url: url);
      final relayType = await relayTypeKeyPackage();

      final currentRelayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      final refreshedPublicKey = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      final refreshedRelayType = await relayTypeKeyPackage();

      await updateRelays(
        pubkey: refreshedPublicKey,
        relayType: refreshedRelayType,
        relays: [...currentRelayUrls, relayUrl],
      );

      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add relay: $e');
    }
  }

  Future<void> deleteRelay(String url) async {
    try {
      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        _logger.severe('RelayProvider: No active account found for deleting relay');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayType = await relayTypeKeyPackage();

      final currentRelayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );

      // Filter out the relay to delete
      final List<RelayUrl> updatedRelayUrls = [];
      for (final relayUrl in currentRelayUrls) {
        final urlString = await stringFromRelayUrl(relayUrl: relayUrl);
        if (urlString != url) {
          updatedRelayUrls.add(relayUrl);
        }
      }

      final refreshedPublicKey = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      final refreshedRelayType = await relayTypeKeyPackage();

      await updateRelays(
        pubkey: refreshedPublicKey,
        relayType: refreshedRelayType,
        relays: updatedRelayUrls,
      );

      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete relay: $e');
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
