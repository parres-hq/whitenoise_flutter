import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

// State for relay status management
class RelayStatusState {
  final Map<String, String> relayStatuses;
  final bool isLoading;
  final String? error;

  const RelayStatusState({
    this.relayStatuses = const {},
    this.isLoading = false,
    this.error,
  });

  RelayStatusState copyWith({
    Map<String, String>? relayStatuses,
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

      // Get the active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      _logger.info('RelayStatusNotifier: Active account data: ${activeAccountData?.pubkey}');
      if (activeAccountData == null) {
        _logger.warning('RelayStatusNotifier: No active account found');
        state = state.copyWith(isLoading: false, error: 'No active account found');
        return;
      }

      // Convert pubkey string to PublicKey object
      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);

      _logger.info(
        'RelayStatusNotifier: Fetching relay statuses for pubkey: ${activeAccountData.pubkey}',
      );
      // Fetch relay statuses using the Rust function
      final relayStatuses = await fetchRelayStatus(pubkey: publicKey);
      _logger.info('RelayStatusNotifier: Fetched ${relayStatuses.length} relay statuses');

      // Convert list of tuples to map
      final statusMap = <String, String>{};
      for (final (url, status) in relayStatuses) {
        statusMap[url] = status;
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

  String getRelayStatus(String url) {
    return state.relayStatuses[url] ?? 'Unknown';
  }

  bool isRelayConnected(String url) {
    final status = getRelayStatus(url);
    return status.toLowerCase() == 'connected';
  }
}

// Provider
final relayStatusProvider = NotifierProvider<RelayStatusNotifier, RelayStatusState>(
  RelayStatusNotifier.new,
);
