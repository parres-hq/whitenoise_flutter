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

      final relayUrls = activeAccountData.nip65Relays;
      _logger.info('NormalRelaysNotifier: Fetching relays for pubkey: ${activeAccountData.pubkey}');

      _logger.info('NormalRelaysNotifier: Fetched ${relayUrls.length} relay URLs');

      // If no relays found, log this information
      if (relayUrls.isEmpty) {
        _logger.warning('NormalRelaysNotifier: No relays found for user.');
        state = state.copyWith(relays: [], isLoading: false);
        return;
      }

      // Ensure relay status provider is loaded first
      final statusState = ref.read(relayStatusProvider);
      if (statusState.relayStatuses.isEmpty && !statusState.isLoading) {
        _logger.info('NormalRelaysNotifier: Loading relay statuses first');
        await ref.read(relayStatusProvider.notifier).loadRelayStatuses();
      }

      final relayInfos = await Future.wait<RelayInfo>(
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
      state = state.copyWith(relays: relayInfos, isLoading: false);
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
      final accountPubKeyString = ref.read(activeAccountProvider);

      if (accountPubKeyString == null) {
        _logger.severe('RelayProvider: No active account found for adding relay');
        return;
      }
      final publicKey = await publicKeyFromString(publicKeyString: accountPubKeyString);
      final relay = await relayUrlFromString(url: url);

      await addNip65Relay(
        pubkey: publicKey,
        relay: relay,
      );
      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add relay: $e');
    }
  }

  Future<void> deleteRelay(String url) async {
    try {
      final accountPubKeyString = ref.read(activeAccountProvider);
      if (accountPubKeyString == null) {
        _logger.severe('RelayProvider: No active account found for adding relay');
        return;
      }
      final publicKey = await publicKeyFromString(publicKeyString: accountPubKeyString);
      final relay = await relayUrlFromString(url: url);

      await removeNip65Relay(
        pubkey: publicKey,
        relay: relay,
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

      _logger.info('InboxRelaysNotifier: Fetching relays for pubkey: ${activeAccountData.pubkey}');
      final relayUrls = activeAccountData.inboxRelays;

      _logger.info('InboxRelaysNotifier: Fetched ${relayUrls.length} relay URLs');

      // If no relays found, log this information
      if (relayUrls.isEmpty) {
        _logger.warning('InboxRelaysNotifier: No inbox relays found for user.');
        state = state.copyWith(relays: [], isLoading: false);
        return;
      }

      // Ensure relay status provider is loaded first
      final statusState = ref.read(relayStatusProvider);
      if (statusState.relayStatuses.isEmpty && !statusState.isLoading) {
        _logger.info('InboxRelaysNotifier: Loading relay statuses first');
        await ref.read(relayStatusProvider.notifier).loadRelayStatuses();
      }

      final relayInfos = await Future.wait<RelayInfo>(
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
      state = state.copyWith(relays: relayInfos, isLoading: false);
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
      final accountPubKeyString = ref.read(activeAccountProvider);
      if (accountPubKeyString == null) {
        _logger.severe('RelayProvider: No active account found for adding relay');
        return;
      }
      final publicKey = await publicKeyFromString(publicKeyString: accountPubKeyString);
      final relay = await relayUrlFromString(url: url);

      await addInboxRelay(
        pubkey: publicKey,
        relay: relay,
      );
      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add relay: $e');
    }
  }

  Future<void> deleteRelay(String url) async {
    try {
      final accountPubKeyString = ref.read(activeAccountProvider);

      if (accountPubKeyString == null) {
        _logger.severe('RelayProvider: No active account found for adding relay');
        return;
      }
      final publicKey = await publicKeyFromString(publicKeyString: accountPubKeyString);
      final relay = await relayUrlFromString(url: url);

      await removeInboxRelay(
        pubkey: publicKey,
        relay: relay,
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

      _logger.info(
        'KeyPackageRelaysNotifier: Fetching relays for pubkey: ${activeAccountData.pubkey}',
      );
      final relayUrls = activeAccountData.keyPackageRelays;

      _logger.info('KeyPackageRelaysNotifier: Fetched ${relayUrls.length} relay URLs');

      // If no relays found, log this information
      if (relayUrls.isEmpty) {
        _logger.warning('KeyPackageRelaysNotifier: No key package relays found for user.');
        state = state.copyWith(
          relays: [],
          isLoading: false,
        );
        return;
      }

      final relayInfos = await Future.wait<RelayInfo>(
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
      state = state.copyWith(relays: relayInfos, isLoading: false);
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
      final accountPubKeyString = ref.read(activeAccountProvider);
      if (accountPubKeyString == null) {
        _logger.severe('RelayProvider: No active account found for adding relay');
        return;
      }
      final publicKey = await publicKeyFromString(publicKeyString: accountPubKeyString);
      final relay = await relayUrlFromString(url: url);

      await addKeyPackageRelay(
        pubkey: publicKey,
        relay: relay,
      );
      await loadRelays();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add relay: $e');
    }
  }

  Future<void> deleteRelay(String url) async {
    try {
      final accountPubKeyString = ref.read(activeAccountProvider);

      if (accountPubKeyString == null) {
        _logger.severe('RelayProvider: No active account found for adding relay');
        return;
      }
      final publicKey = await publicKeyFromString(publicKeyString: accountPubKeyString);
      final relay = await relayUrlFromString(url: url);

      await removeKeyPackageRelay(
        pubkey: publicKey,
        relay: relay,
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
