// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/models/relay_status.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart';

// State for relay status management
class RelayStatusState {
  final Map<String, RelayStatus> relayStatuses;
  final bool isLoading;
  final String? error;

  const RelayStatusState({
    this.relayStatuses = const {},
    this.isLoading = false,
    this.error,
  });

  RelayStatusState copyWith({
    Map<String, RelayStatus>? relayStatuses,
    bool? isLoading,
    String? error,
  }) {
    return RelayStatusState(
      relayStatuses: relayStatuses ?? this.relayStatuses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Relay status notifier
class RelayStatusNotifier extends Notifier<RelayStatusState> {
  final _logger = Logger('RelayStatusNotifier');

  @override
  RelayStatusState build() {
    // Initialize with loading state and trigger load
    Future.microtask(() => loadRelayStatuses());
    return const RelayStatusState(isLoading: true);
  }

  Future<void> loadRelayStatuses() async {
    _logger.info('RelayStatusNotifier: Starting to load relay statuses');
    state = state.copyWith(isLoading: true);

    try {
      final authState = ref.read(authProvider);
      _logger.info(
        'RelayStatusNotifier: Auth state - isAuthenticated: ${authState.isAuthenticated}',
      );
      if (!authState.isAuthenticated) {
        _logger.warning('RelayStatusNotifier: Not authenticated');
        state = state.copyWith(
          isLoading: false,
          error: 'Not authenticated',
        );
        return;
      }

      final activePubkey = ref.read(activePubkeyProvider);
      _logger.info('RelayStatusNotifier: Active account data: $activePubkey');
      if (activePubkey == null || activePubkey.isEmpty) {
        _logger.warning('RelayStatusNotifier: No active account found');
        state = state.copyWith(isLoading: false, error: 'No active account found');
        return;
      }

      _logger.info(
        'RelayStatusNotifier: Fetching relay statuses for pubkey: $activePubkey',
      );
      // Fetch relay statuses using the Rust function
      final relayStatuses = await fetchRelayStatus(pubkey: activePubkey);
      _logger.info('RelayStatusNotifier: Fetched ${relayStatuses.length} relay statuses');

      // Convert list of tuples to map
      final statusMap = <String, RelayStatus>{};
      for (final (url, status) in relayStatuses) {
        statusMap[url] = RelayStatus.fromString(status);
        _logger.info('RelayStatusNotifier: Relay $url has status: $status');
      }

      // If no relay statuses found, log this information
      if (statusMap.isEmpty) {
        _logger.info('RelayStatusNotifier: No relay statuses found.');
      }

      _logger.info('RelayStatusNotifier: Successfully loaded ${statusMap.length} relay statuses');
      state = state.copyWith(relayStatuses: statusMap, isLoading: false);
    } catch (e, stackTrace) {
      _logger.severe('RelayStatusNotifier: Error loading relay statuses: $e', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading relay statuses: $e',
      );
    }
  }

  Future<void> refreshStatuses() async {
    await loadRelayStatuses();
  }

  RelayStatus getRelayStatus(String url) {
    return state.relayStatuses[url] ?? RelayStatus.disconnected;
  }

  bool isRelayConnected(String url) {
    final status = getRelayStatus(url);
    return status.isConnected;
  }

  Future<bool> areAllRelayTypesConnected() async {
    try {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        return false;
      }

      // Read the active account pubkey string
      final accountPubKey = ref.read(activePubkeyProvider);
      if (accountPubKey == null) return false;

      // Fetch relay URLs for each type using new bridge methods
      final nip65Type = await relayTypeNip65();
      final inboxType = await relayTypeInbox();
      final keyPackageType = await relayTypeKeyPackage();

      final nip65Urls =
          (await accountRelays(
            pubkey: accountPubKey,
            relayType: nip65Type,
          )).map((r) => r.url).toList();
      final inboxUrls =
          (await accountRelays(
            pubkey: accountPubKey,
            relayType: inboxType,
          )).map((r) => r.url).toList();
      final keyPackageUrls =
          (await accountRelays(
            pubkey: accountPubKey,
            relayType: keyPackageType,
          )).map((r) => r.url).toList();

      // Check each relay type separately using URL strings
      final hasConnectedNostr = await _hasConnectedRelayOfType(nip65Urls);
      final hasConnectedInbox = await _hasConnectedRelayOfType(inboxUrls);
      final hasConnectedKeyPackage = await _hasConnectedRelayOfType(keyPackageUrls);

      return hasConnectedNostr && hasConnectedInbox && hasConnectedKeyPackage;
    } catch (e) {
      _logger.warning('Error checking relay type connections: $e');
      return false;
    }
  }

  Future<bool> _hasConnectedRelayOfType(List<String> relayUrls) async {
    if (relayUrls.isEmpty) {
      return false;
    }

    for (final url in relayUrls) {
      if (isRelayConnected(url)) {
        return true;
      }
    }

    return false;
  }
}

// Provider
final relayStatusProvider = NotifierProvider<RelayStatusNotifier, RelayStatusState>(
  RelayStatusNotifier.new,
);

// Provider for checking if all relay types have at least one connected relay
final allRelayTypesConnectionProvider = FutureProvider<bool>((ref) async {
  // Watch the relay status provider to trigger rebuilds when statuses change
  ref.watch(relayStatusProvider);

  final notifier = ref.read(relayStatusProvider.notifier);
  return await notifier.areAllRelayTypesConnected();
});
