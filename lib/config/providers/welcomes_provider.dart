import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/welcome_state.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';

class WelcomesNotifier extends Notifier<WelcomesState> {
  final _logger = Logger('WelcomesNotifier');

  // Callback for when a new pending welcome is available
  void Function(WelcomeData)? _onNewWelcomeCallback;

  @override
  WelcomesState build() => const WelcomesState();

  /// Set a callback that will be triggered when a new pending welcome is detected
  void setOnNewWelcomeCallback(void Function(WelcomeData)? callback) {
    _onNewWelcomeCallback = callback;
  }

  bool _isAuthAvailable() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return false;
    }
    return true;
  }

  Future<void> loadWelcomes() async {
    state = state.copyWith(isLoading: true, error: null);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final welcomes = await fetchWelcomes(pubkey: publicKey);

      final welcomeByData = <String, WelcomeData>{};
      for (final welcome in welcomes) {
        welcomeByData[welcome.id] = welcome;
      }

      // Get current pending welcomes to compare
      final previousPendingIds = getPendingWelcomes().map((w) => w.id).toSet();

      state = state.copyWith(
        welcomes: welcomes,
        welcomeById: welcomeByData,
        isLoading: false,
      );

      // Find new pending welcomes and trigger callback for the first one
      final newPendingWelcomes =
          welcomes
              .where((w) => w.state == WelcomeState.pending && !previousPendingIds.contains(w.id))
              .toList();

      if (newPendingWelcomes.isNotEmpty && _onNewWelcomeCallback != null) {
        _logger.info(
          'WelcomesProvider: Found ${newPendingWelcomes.length} new pending welcomes, showing first one',
        );
        _onNewWelcomeCallback!(newPendingWelcomes.first);
      }
    } catch (e, st) {
      _logger.severe('WelcomesProvider.loadWelcomes', e, st);
      String errorMessage = 'Failed to load welcomes';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to load welcomes due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage, isLoading: false);
    }
  }

  Future<WelcomeData?> fetchWelcomeById(String welcomeEventId) async {
    if (!_isAuthAvailable()) {
      return null;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return null;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final welcome = await fetchWelcome(pubkey: publicKey, welcomeEventId: welcomeEventId);

      final updatedWelcomeById = Map<String, WelcomeData>.from(state.welcomeById ?? {});
      updatedWelcomeById[welcome.id] = welcome;

      state = state.copyWith(welcomeById: updatedWelcomeById);
      return welcome;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.fetchWelcomeById', e, st);
      String errorMessage = 'Failed to fetch welcome';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to fetch welcome due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
      return null;
    }
  }

  Future<bool> acceptWelcomeInvitation(String welcomeEventId) async {
    if (!_isAuthAvailable()) {
      return false;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return false;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      await acceptWelcome(pubkey: publicKey, welcomeEventId: welcomeEventId);

      // Update the welcome state to accepted
      await _updateWelcomeState(welcomeEventId, WelcomeState.accepted);

      _logger.info('WelcomesProvider: Welcome accepted successfully - $welcomeEventId');
      return true;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.acceptWelcomeInvitation', e, st);
      String errorMessage = 'Failed to accept welcome';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to accept welcome due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> declineWelcomeInvitation(String welcomeEventId) async {
    if (!_isAuthAvailable()) {
      return false;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return false;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      await declineWelcome(pubkey: publicKey, welcomeEventId: welcomeEventId);

      // Update the welcome state to declined
      await _updateWelcomeState(welcomeEventId, WelcomeState.declined);

      _logger.info('WelcomesProvider: Welcome declined successfully - $welcomeEventId');
      return true;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.declineWelcomeInvitation', e, st);
      String errorMessage = 'Failed to decline welcome';
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          _logger.warning('Failed to convert WhitenoiseError to string: $conversionError');
          errorMessage = 'Failed to decline welcome due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Mark a welcome as ignored (dismissed without action)
  Future<bool> ignoreWelcome(String welcomeEventId) async {
    try {
      // Update the welcome state to ignored locally
      await _updateWelcomeState(welcomeEventId, WelcomeState.ignored);
      _logger.info('WelcomesProvider: Welcome ignored - $welcomeEventId');
      return true;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.ignoreWelcome', e, st);
      state = state.copyWith(error: 'Failed to ignore welcome');
      return false;
    }
  }

  Future<void> _updateWelcomeState(String welcomeEventId, WelcomeState newState) async {
    final currentWelcome = state.welcomeById?[welcomeEventId];
    if (currentWelcome != null) {
      final updatedWelcome = WelcomeData(
        id: currentWelcome.id,
        mlsGroupId: currentWelcome.mlsGroupId,
        nostrGroupId: currentWelcome.nostrGroupId,
        groupName: currentWelcome.groupName,
        groupDescription: currentWelcome.groupDescription,
        groupAdminPubkeys: currentWelcome.groupAdminPubkeys,
        groupRelays: currentWelcome.groupRelays,
        welcomer: currentWelcome.welcomer,
        memberCount: currentWelcome.memberCount,
        state: newState,
        createdAt: currentWelcome.createdAt,
      );

      final updatedWelcomeById = Map<String, WelcomeData>.from(state.welcomeById ?? {});
      updatedWelcomeById[welcomeEventId] = updatedWelcome;

      final updatedWelcomes =
          state.welcomes?.map((welcome) {
            return welcome.id == welcomeEventId ? updatedWelcome : welcome;
          }).toList();

      state = state.copyWith(
        welcomes: updatedWelcomes,
        welcomeById: updatedWelcomeById,
      );
    }
  }

  List<WelcomeData> getPendingWelcomes() {
    final welcomes = state.welcomes;
    if (welcomes == null) return [];
    return welcomes.where((welcome) => welcome.state == WelcomeState.pending).toList();
  }

  List<WelcomeData> getAcceptedWelcomes() {
    final welcomes = state.welcomes;
    if (welcomes == null) return [];
    return welcomes.where((welcome) => welcome.state == WelcomeState.accepted).toList();
  }

  List<WelcomeData> getDeclinedWelcomes() {
    final welcomes = state.welcomes;
    if (welcomes == null) return [];
    return welcomes.where((welcome) => welcome.state == WelcomeState.declined).toList();
  }

  WelcomeData? getWelcomeById(String welcomeId) {
    return state.welcomeById?[welcomeId];
  }

  void clearWelcomeData() {
    state = const WelcomesState();
  }

  Future<void> refreshWelcomes() async {
    await loadWelcomes();
  }

  /// Trigger callback for a specific welcome invitation
  void triggerWelcomeCallback(WelcomeData welcomeData) {
    if (_onNewWelcomeCallback != null && welcomeData.state == WelcomeState.pending) {
      _logger.info('WelcomesProvider: Triggering callback for welcome ${welcomeData.id}');
      _onNewWelcomeCallback!(welcomeData);
    }
  }

  /// Clear the callback
  void clearOnNewWelcomeCallback() {
    _onNewWelcomeCallback = null;
  }

  /// Show next pending welcome if available
  void showNextPendingWelcome() {
    final pendingWelcomes = getPendingWelcomes();
    if (pendingWelcomes.isNotEmpty && _onNewWelcomeCallback != null) {
      _logger.info('WelcomesProvider: Showing next pending welcome');
      _onNewWelcomeCallback!(pendingWelcomes.first);
    } else {
      _logger.info('WelcomesProvider: No more pending welcomes to show');
    }
  }

  /// Check for new welcomes and add them incrementally (for polling)
  Future<void> checkForNewWelcomes() async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final newWelcomes = await fetchWelcomes(pubkey: publicKey);

      final currentWelcomes = state.welcomes ?? [];
      final currentWelcomeIds = currentWelcomes.map((w) => w.id).toSet();

      // Find truly new welcomes
      final actuallyNewWelcomes =
          newWelcomes.where((welcome) => !currentWelcomeIds.contains(welcome.id)).toList();

      if (actuallyNewWelcomes.isNotEmpty) {
        // Add new welcomes to existing list
        final updatedWelcomes = [...currentWelcomes, ...actuallyNewWelcomes];

        // Update welcomeById map
        final welcomeByData = Map<String, WelcomeData>.from(state.welcomeById ?? {});
        for (final welcome in actuallyNewWelcomes) {
          welcomeByData[welcome.id] = welcome;
        }

        state = state.copyWith(
          welcomes: updatedWelcomes,
          welcomeById: welcomeByData,
        );

        // Trigger callback for new pending welcomes
        final newPendingWelcomes =
            actuallyNewWelcomes.where((w) => w.state == WelcomeState.pending).toList();

        if (newPendingWelcomes.isNotEmpty && _onNewWelcomeCallback != null) {
          _logger.info('WelcomesProvider: Found ${newPendingWelcomes.length} new pending welcomes');
          _onNewWelcomeCallback!(newPendingWelcomes.first);
        }

        _logger.info('WelcomesProvider: Added ${actuallyNewWelcomes.length} new welcomes');
      }
    } catch (e, st) {
      _logger.severe('WelcomesProvider.checkForNewWelcomes', e, st);
    }
  }
}

final welcomesProvider = NotifierProvider<WelcomesNotifier, WelcomesState>(
  WelcomesNotifier.new,
);
