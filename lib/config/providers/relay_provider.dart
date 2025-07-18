// ignore_for_file: avoid_redundant_argument_values

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
    // Initialize with loading state and trigger load
    Future.microtask(() => loadRelays());
    return const RelayState(isLoading: true);
  }

  Future<void> loadRelays() async {
    _logger.info('NormalRelaysNotifier: Starting to load relays');
    state = state.copyWith(isLoading: true);

    try {
      final authState = ref.read(authProvider);
      _logger.info(
        'NormalRelaysNotifier: Auth state - isAuthenticated: ${authState.isAuthenticated}',
      );
      if (!authState.isAuthenticated) {
        _logger.warning('NormalRelaysNotifier: Not authenticated');
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated',
        );
        return;
      }

      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      _logger.info('NormalRelaysNotifier: Active account data: ${activeAccountData?.pubkey}');
      if (activeAccountData == null) {
        _logger.warning('NormalRelaysNotifier: No active account found');
        state = state.copyWith(isLoading: false, error: 'No active account found');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayType = await relayTypeNostr();

      _logger.info('NormalRelaysNotifier: Fetching relays for pubkey: ${activeAccountData.pubkey}');
      final relayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );
      _logger.info('NormalRelaysNotifier: Fetched ${relayUrls.length} relay URLs');

      // If no relays found, log this information
      if (relayUrls.isEmpty) {
        _logger.warning('NormalRelaysNotifier: No relays found for user.');
        state = state.copyWith(
          relays: [],
          isLoading: false,
          error: null, // Clear any previous errors
        );
        return;
      }

      // Ensure relay status provider is loaded first
      final statusState = ref.read(relayStatusProvider);
      if (statusState.relayStatuses.isEmpty && !statusState.isLoading) {
        _logger.info('NormalRelaysNotifier: Loading relay statuses first');
        await ref.read(relayStatusProvider.notifier).loadRelayStatuses();
      }

      final relayInfos = await Future.wait(
        relayUrls.map((relayUrl) async {
          final url = await stringFromRelayUrl(relayUrl: relayUrl);
          // Get status from relay status provider
          final statusNotifier = ref.read(relayStatusProvider.notifier);
          final status = statusNotifier.getRelayStatus(url);
          final connected = statusNotifier.isRelayConnected(url);
          _logger.info('NormalRelaysNotifier: Relay $url - status: $status, connected: $connected');
          return RelayInfo(url: url, connected: connected, status: status);
        }),
      );

      _logger.info('NormalRelaysNotifier: Successfully loaded ${relayInfos.length} relays');
      state = state.copyWith(relays: relayInfos, isLoading: false, error: null);
    } catch (e, stackTrace) {
      _logger.severe('NormalRelaysNotifier: Error loading relays: $e', e, stackTrace);
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
    // Initialize with loading state and trigger load
    Future.microtask(() => loadRelays());
    return const RelayState(isLoading: true);
  }

  Future<void> loadRelays() async {
    _logger.info('InboxRelaysNotifier: Starting to load relays');
    state = state.copyWith(isLoading: true);

    try {
      final authState = ref.read(authProvider);
      _logger.info(
        'InboxRelaysNotifier: Auth state - isAuthenticated: ${authState.isAuthenticated}',
      );
      if (!authState.isAuthenticated) {
        _logger.warning('InboxRelaysNotifier: Not authenticated');
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated',
        );
        return;
      }

      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      _logger.info('InboxRelaysNotifier: Active account data: ${activeAccountData?.pubkey}');
      if (activeAccountData == null) {
        _logger.warning('InboxRelaysNotifier: No active account found');
        state = state.copyWith(isLoading: false, error: 'No active account found');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayType = await relayTypeInbox();

      _logger.info('InboxRelaysNotifier: Fetching relays for pubkey: ${activeAccountData.pubkey}');
      final relayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );
      _logger.info('InboxRelaysNotifier: Fetched ${relayUrls.length} relay URLs');

      // If no relays found, log this information
      if (relayUrls.isEmpty) {
        _logger.warning('InboxRelaysNotifier: No inbox relays found for user.');
        state = state.copyWith(
          relays: [],
          isLoading: false,
          error: null, // Clear any previous errors
        );
        return;
      }

      // Ensure relay status provider is loaded first
      final statusState = ref.read(relayStatusProvider);
      if (statusState.relayStatuses.isEmpty && !statusState.isLoading) {
        _logger.info('InboxRelaysNotifier: Loading relay statuses first');
        await ref.read(relayStatusProvider.notifier).loadRelayStatuses();
      }

      final relayInfos = await Future.wait(
        relayUrls.map((relayUrl) async {
          final url = await stringFromRelayUrl(relayUrl: relayUrl);
          // Get status from relay status provider
          final statusNotifier = ref.read(relayStatusProvider.notifier);
          final status = statusNotifier.getRelayStatus(url);
          final connected = statusNotifier.isRelayConnected(url);
          _logger.info('InboxRelaysNotifier: Relay $url - status: $status, connected: $connected');
          return RelayInfo(url: url, connected: connected, status: status);
        }),
      );

      _logger.info('InboxRelaysNotifier: Successfully loaded ${relayInfos.length} relays');
      state = state.copyWith(relays: relayInfos, isLoading: false, error: null);
    } catch (e, stackTrace) {
      _logger.severe('InboxRelaysNotifier: Error loading relays: $e', e, stackTrace);
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
    // Initialize with loading state and trigger load
    Future.microtask(() => loadRelays());
    return const RelayState(isLoading: true);
  }

  Future<void> loadRelays() async {
    _logger.info('KeyPackageRelaysNotifier: Starting to load relays');
    state = state.copyWith(isLoading: true);

    try {
      final authState = ref.read(authProvider);
      _logger.info(
        'KeyPackageRelaysNotifier: Auth state - isAuthenticated: ${authState.isAuthenticated}',
      );
      if (!authState.isAuthenticated) {
        _logger.warning('KeyPackageRelaysNotifier: Not authenticated');
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated',
        );
        return;
      }

      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      _logger.info('KeyPackageRelaysNotifier: Active account data: ${activeAccountData?.pubkey}');
      if (activeAccountData == null) {
        _logger.warning('KeyPackageRelaysNotifier: No active account found');
        state = state.copyWith(isLoading: false, error: 'No active account found');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final relayType = await relayTypeKeyPackage();

      _logger.info(
        'KeyPackageRelaysNotifier: Fetching relays for pubkey: ${activeAccountData.pubkey}',
      );
      final relayUrls = await fetchRelays(
        pubkey: publicKey,
        relayType: relayType,
      );
      _logger.info('KeyPackageRelaysNotifier: Fetched ${relayUrls.length} relay URLs');

      // If no relays found, log this information
      if (relayUrls.isEmpty) {
        _logger.warning('KeyPackageRelaysNotifier: No key package relays found for user.');
        state = state.copyWith(
          relays: [],
          isLoading: false,
          error: null, // Clear any previous errors
        );
        return;
      }

      final relayInfos = await Future.wait(
        relayUrls.map((relayUrl) async {
          final url = await stringFromRelayUrl(relayUrl: relayUrl);
          // Get status from relay status provider
          final statusNotifier = ref.read(relayStatusProvider.notifier);
          final status = statusNotifier.getRelayStatus(url);
          final connected = statusNotifier.isRelayConnected(url);
          _logger.info(
            'KeyPackageRelaysNotifier: Relay $url - status: $status, connected: $connected',
          );
          return RelayInfo(url: url, connected: connected, status: status);
        }),
      );

      _logger.info('KeyPackageRelaysNotifier: Successfully loaded ${relayInfos.length} relays');
      state = state.copyWith(relays: relayInfos, isLoading: false, error: null);
    } catch (e, stackTrace) {
      _logger.severe('KeyPackageRelaysNotifier: Error loading relays: $e', e, stackTrace);
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
