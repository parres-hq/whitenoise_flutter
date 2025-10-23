import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/user_profile_provider.dart';
import 'package:whitenoise/config/states/welcome_state.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/error.dart' show ApiError;
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class WelcomesNotifier extends Notifier<WelcomesState> {
  final _logger = Logger('WelcomesNotifier');

  void Function(Welcome)? _onNewWelcomeCallback;

  @override
  WelcomesState build() {
    ref.listen<String?>(activePubkeyProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        // Schedule state changes after the build phase to avoid provider modification errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearWelcome();
          loadWelcomes();
        });
      } else if (previous != null && next == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          clearWelcome();
        });
      } else if (previous == null && next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          loadWelcomes();
        });
      }
    });

    return const WelcomesState();
  }

  void setOnNewWelcomeCallback(void Function(Welcome)? callback) {
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
      final String activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return;
      }

      final String requestPubkey = activePubkey;
      final welcomes = await pendingWelcomes(pubkey: requestPubkey);
      if (requestPubkey != (ref.read(activePubkeyProvider) ?? '')) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final welcomeByData = <String, Welcome>{};
      for (final welcome in welcomes) {
        welcomeByData[welcome.id] = welcome;
      }

      final previousPendingIds = getPendingWelcomes().map((w) => w.id).toSet();

      state = state.copyWith(
        welcomes: welcomes,
        welcomeById: welcomeByData,
        isLoading: false,
      );

      final activePubkeySnapshot = activePubkey;
      Future.microtask(() => _loadWelcomerUsersDataIncrementally(welcomes, activePubkeySnapshot));

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
      if (e is ApiError) {
        errorMessage = await e.messageText();
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(error: errorMessage, isLoading: false);
    }
  }

  /// Process welcomer metadata in batches with customizable error handling
  /// Used by both initial loading and retry logic to fetch user metadata
  Future<List<String>> _processBatchedWelcomers({
    required List<String> pubkeys,
    required Map<String, User> welcomerUsers,
    required bool createFallbacks,
    required String? batchLogContext,
  }) async {
    const batchSize = 6;
    final failedPubkeys = <String>[];

    for (int i = 0; i < pubkeys.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, pubkeys.length);
      final batch = pubkeys.sublist(i, end);

      await Future.wait(
        batch.map((welcomerPubkey) async {
          try {
            final rustUser = await ref.read(userProfileProvider.notifier).getUser(welcomerPubkey);
            final user = User.fromMetadata(rustUser.metadata, welcomerPubkey);
            welcomerUsers[welcomerPubkey] = user;
          } catch (e) {
            _logger.warning('Failed to fetch metadata for welcomer $welcomerPubkey: $e');
            if (createFallbacks) {
              welcomerUsers[welcomerPubkey] = User(
                id: welcomerPubkey,
                displayName: 'shared.unknownUser'.tr(),
                nip05: '',
                publicKey: welcomerPubkey,
              );
            } else {
              failedPubkeys.add(welcomerPubkey);
            }
          }
        }),
      );

      state = state.copyWith(welcomerUsers: welcomerUsers);
      if (batchLogContext != null) {
        _logger.info('WelcomesProvider: $batchLogContext batch of ${batch.length} welcomers');
      }
    }

    return failedPubkeys;
  }

  /// Load welcomer metadata in batches so welcomes appear incrementally (6 per batch)
  Future<void> _loadWelcomerUsersDataIncrementally(
    List<Welcome> welcomes,
    String activePubkey,
  ) async {
    try {
      if (activePubkey != (ref.read(activePubkeyProvider) ?? '')) {
        return;
      }

      final welcomerUsers = Map<String, User>.from(state.welcomerUsers ?? {});

      final uniqueWelcomers =
          <String>{
            for (final w in welcomes) w.welcomer,
          }.where((k) => !welcomerUsers.containsKey(k)).toList();

      final failedWelcomers = await _processBatchedWelcomers(
        pubkeys: uniqueWelcomers,
        welcomerUsers: welcomerUsers,
        createFallbacks: false,
        batchLogContext: 'Loaded',
      );

      if (failedWelcomers.isNotEmpty) {
        _logger.info('WelcomesProvider: Retrying ${failedWelcomers.length} failed welcomers');
        await _retryFailedWelcomers(failedWelcomers, welcomerUsers);
      }

      _logger.info(
        'WelcomesProvider: Batch loading complete for ${uniqueWelcomers.length} welcomers (${failedWelcomers.length} retried)',
      );
    } catch (e) {
      _logger.warning('Error in batch welcomer loading: $e');
    }
  }

  /// Retry failed welcomer metadata loads with exponential backoff
  /// Uses batch processing with eventual fallback creation for persistent failures
  Future<void> _retryFailedWelcomers(
    List<String> failedWelcomers,
    Map<String, User> welcomerUsers,
  ) async {
    const maxRetries = 2;
    var remainingWelcomers = failedWelcomers;

    for (int attempt = 1; attempt <= maxRetries && remainingWelcomers.isNotEmpty; attempt++) {
      final delayMs = 500 * attempt;
      await Future.delayed(Duration(milliseconds: delayMs));

      // Batch process with fallback creation on final attempt
      final stillFailed = await _processBatchedWelcomers(
        pubkeys: remainingWelcomers,
        welcomerUsers: welcomerUsers,
        createFallbacks: attempt == maxRetries, // Create fallbacks on last attempt
        batchLogContext: 'Retry $attempt:',
      );

      remainingWelcomers = stillFailed;
    }

    if (remainingWelcomers.isNotEmpty) {
      _logger.warning(
        'WelcomesProvider: Failed to load ${remainingWelcomers.length} welcomers after $maxRetries retries: '
        '${remainingWelcomers.join(", ")}',
      );
    }
  }

  Future<Welcome?> fetchWelcomeById(String welcomeEventId) async {
    if (!_isAuthAvailable()) {
      return null;
    }

    try {
      final String activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found');
        return null;
      }

      final String requestPubkey = activePubkey;
      final welcome = await findWelcomeByEventId(
        pubkey: requestPubkey,
        welcomeEventId: welcomeEventId,
      );
      if (requestPubkey != (ref.read(activePubkeyProvider) ?? '')) {
        return null;
      }

      final updatedWelcomeById = Map<String, Welcome>.from(state.welcomeById ?? {});
      updatedWelcomeById[welcome.id] = welcome;

      state = state.copyWith(welcomeById: updatedWelcomeById);
      return welcome;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.fetchWelcomeById', e, st);
      String errorMessage = 'Failed to fetch welcome';
      if (e is ApiError) {
        errorMessage = await e.messageText();
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
      final String activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found');
        return false;
      }

      final String requestPubkey = activePubkey;
      await acceptWelcome(pubkey: requestPubkey, welcomeEventId: welcomeEventId);
      if (requestPubkey != (ref.read(activePubkeyProvider) ?? '')) {
        return false;
      }

      await _updateWelcomeState(welcomeEventId, WelcomeState.accepted);

      _logger.info('WelcomesProvider: Welcome accepted successfully - $welcomeEventId');
      return true;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.acceptWelcomeInvitation', e, st);
      String errorMessage = 'Failed to accept welcome';
      if (e is ApiError) {
        errorMessage = await e.messageText();
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
      final String activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found');
        return false;
      }

      final String requestPubkey = activePubkey;
      await declineWelcome(pubkey: requestPubkey, welcomeEventId: welcomeEventId);
      if (requestPubkey != (ref.read(activePubkeyProvider) ?? '')) {
        return false;
      }

      await _updateWelcomeState(welcomeEventId, WelcomeState.declined);

      _logger.info('WelcomesProvider: Welcome declined successfully - $welcomeEventId');
      return true;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.declineWelcomeInvitation', e, st);
      String errorMessage = 'Failed to decline welcome';
      if (e is ApiError) {
        errorMessage = await e.messageText();
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
      final updatedWelcome = Welcome(
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

      final updatedWelcomeById = Map<String, Welcome>.from(state.welcomeById ?? {});
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

  List<Welcome> getPendingWelcomes() {
    final welcomes = state.welcomes;
    if (welcomes == null) return [];
    return welcomes.where((welcome) => welcome.state == WelcomeState.pending).toList();
  }

  List<Welcome> getAcceptedWelcomes() {
    final welcomes = state.welcomes;
    if (welcomes == null) return [];
    return welcomes.where((welcome) => welcome.state == WelcomeState.accepted).toList();
  }

  List<Welcome> getDeclinedWelcomes() {
    final welcomes = state.welcomes;
    if (welcomes == null) return [];
    return welcomes.where((welcome) => welcome.state == WelcomeState.declined).toList();
  }

  Welcome? getWelcomeById(String welcomeId) {
    return state.welcomeById?[welcomeId];
  }

  User? getWelcomerUser(String welcomerPubkey) {
    return state.welcomerUsers?[welcomerPubkey];
  }

  void clearWelcome() {
    state = const WelcomesState();
  }

  Future<void> refreshWelcomes() async {
    await loadWelcomes();
  }

  /// Trigger callback for a specific welcome invitation
  void triggerWelcomeCallback(Welcome welcome) {
    if (_onNewWelcomeCallback != null && welcome.state == WelcomeState.pending) {
      _logger.info('WelcomesProvider: Triggering callback for welcome ${welcome.id}');
      _onNewWelcomeCallback!(welcome);
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

  /// Refresh welcomer metadata for all welcomes to catch profile updates
  /// Forces refresh even for cached welcomers using batch processing
  Future<void> _refreshWelcomerMetadata(List<Welcome> welcomes, String activePubkey) async {
    try {
      if (activePubkey != (ref.read(activePubkeyProvider) ?? '')) {
        return;
      }

      final welcomerUsers = Map<String, User>.from(state.welcomerUsers ?? {});

      final uniqueWelcomers =
          <String>{
            for (final w in welcomes) w.welcomer,
          }.toList();

      await _processBatchedWelcomers(
        pubkeys: uniqueWelcomers,
        welcomerUsers: welcomerUsers,
        createFallbacks: false,
        batchLogContext: 'Refreshed',
      );

      _logger.info('WelcomesProvider: Refreshed metadata for ${uniqueWelcomers.length} welcomers');
    } catch (e) {
      _logger.warning('Error refreshing welcomer metadata: $e');
    }
  }

  /// Check for new welcomes and add them incrementally (for polling)
  Future<void> checkForNewWelcomes() async {
    if (!_isAuthAvailable()) {
      return;
    }

    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        return;
      }

      final String requestPubkey = activePubkey;
      final newWelcomes = await pendingWelcomes(pubkey: requestPubkey);
      if (requestPubkey != ref.read(activePubkeyProvider)) {
        return;
      }

      final currentWelcomes = state.welcomes ?? [];
      final currentWelcomeIds = currentWelcomes.map((w) => w.id).toSet();

      final actuallyNewWelcomes =
          newWelcomes.where((welcome) => !currentWelcomeIds.contains(welcome.id)).toList();

      if (actuallyNewWelcomes.isNotEmpty) {
        final updatedWelcomes = [...currentWelcomes, ...actuallyNewWelcomes];

        final welcomeByData = Map<String, Welcome>.from(state.welcomeById ?? {});
        for (final welcome in actuallyNewWelcomes) {
          welcomeByData[welcome.id] = welcome;
        }

        state = state.copyWith(
          welcomes: updatedWelcomes,
          welcomeById: welcomeByData,
        );

        Future.microtask(
          () => _loadWelcomerUsersDataIncrementally(actuallyNewWelcomes, activePubkey),
        );

        final newPendingWelcomes =
            actuallyNewWelcomes.where((w) => w.state == WelcomeState.pending).toList();

        if (newPendingWelcomes.isNotEmpty && _onNewWelcomeCallback != null) {
          _logger.info('WelcomesProvider: Found ${newPendingWelcomes.length} new pending welcomes');
          _onNewWelcomeCallback!(newPendingWelcomes.first);
        }

        _logger.info('WelcomesProvider: Added ${actuallyNewWelcomes.length} new welcomes');
      }

      // Refresh metadata for all welcomers to catch profile updates from polling
      Future.microtask(() => _refreshWelcomerMetadata(newWelcomes, activePubkey));
    } catch (e, st) {
      _logger.severe('WelcomesProvider.checkForNewWelcomes', e, st);
    }
  }
}

final welcomesProvider = NotifierProvider<WelcomesNotifier, WelcomesState>(
  WelcomesNotifier.new,
);
