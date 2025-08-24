import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/welcome_state.dart' as wnWelcomeStateApi;
import 'package:whitenoise/src/rust/api.dart' as wnApi;
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart' as wnWelcomesApi;

class WelcomesNotifier extends Notifier<wnWelcomeStateApi.WelcomeState> {
  final _logger = Logger('WelcomesNotifier');

  void Function(wnWelcomesApi.Welcome)? _onNewWelcomeCallback;

  @override
  wnWelcomeStateApi.WelcomeState build() {
    // Listen to active account changes and refresh welcomes automatically
    ref.listen<String?>(activeAccountProvider, (previous, next) {
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

    return const wnWelcomeStateApi.WelcomeState();
  }

  void setOnNewWelcomeCallback(void Function(wnWelcomesApi.Welcome)? callback) {
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
      final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccount();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return;
      }

      final welcomes = await wnWelcomesApi.pendingWelcomes(pubkey: activeAccountData.pubkey);

      final welcomeByData = <String, wnWelcomesApi.Welcome>{};
      // TODO big plans: load welcomes maped by id?
      // for (final welcome in welcomes) {
      //   welcomeByData[welcome.id] = welcome;
      // }

      state = state.copyWith(
        welcomes: welcomes,
        welcomeById: welcomeByData,
        isLoading: false,
      );

      // Find new pending welcomes and trigger callback for the first one
      final pendingWelcomes = await getPendingWelcomes();
      if (pendingWelcomes.isNotEmpty && _onNewWelcomeCallback != null) {
        _logger.info(
          'WelcomesProvider: Found ${pendingWelcomes.length} new pending welcomes, showing first one',
        );
        _onNewWelcomeCallback!(pendingWelcomes.first);
      }
    } catch (e, st) {
      _logger.severe('WelcomesProvider.loadWelcomes', e, st);
      String errorMessage = 'Failed to load welcomes';
      if (e is wnApi.WhitenoiseError) {
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

  Future<wnWelcomesApi.Welcome?> fetchWelcomeById(String welcomeEventId) async {
    if (!_isAuthAvailable()) {
      return null;
    }

    try {
      final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccount();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return null;
      }

      final welcome = await wnWelcomesApi.findWeclcomeByEventId(
        pubkey: activeAccountData.pubkey,
        welcomeEventId: welcomeEventId,
      );

      final updatedWelcomeById = Map<String, wnWelcomesApi.Welcome>.from(state.welcomeById ?? {});
      // TODO big plans: load welcomes maped by id?
      // updatedWelcomeById[welcome.id] = welcome;

      state = state.copyWith(welcomeById: updatedWelcomeById);
      return welcome;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.fetchWelcomeById', e, st);
      String errorMessage = 'Failed to fetch welcome';
      if (e is wnApi.WhitenoiseError) {
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
      final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccount();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return false;
      }

      await wnWelcomesApi.acceptWelcome(
        pubkey: activeAccountData.pubkey,
        welcomeEventId: welcomeEventId,
      );
      await loadWelcomes();

      _logger.info('WelcomesProvider: Welcome accepted successfully - $welcomeEventId');
      return true;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.acceptWelcomeInvitation', e, st);
      String errorMessage = 'Failed to accept welcome';
      if (e is wnApi.WhitenoiseError) {
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
      final activeAccountData = await ref.read(activeAccountProvider.notifier).getActiveAccount();
      if (activeAccountData == null) {
        state = state.copyWith(error: 'No active account found');
        return false;
      }

      await wnWelcomesApi.declineWelcome(
        pubkey: activeAccountData.pubkey,
        welcomeEventId: welcomeEventId,
      );
      await loadWelcomes();

      _logger.info('WelcomesProvider: Welcome declined successfully - $welcomeEventId');
      return true;
    } catch (e, st) {
      _logger.severe('WelcomesProvider.declineWelcomeInvitation', e, st);
      String errorMessage = 'Failed to decline welcome';
      if (e is wnApi.WhitenoiseError) {
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

  Future<List<wnWelcomesApi.Welcome>> getPendingWelcomes() async {
    final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccount();
    if (activeAccount == null) {
      return [];
    } else {
      final pendingWelcomes = await wnWelcomesApi.pendingWelcomes(pubkey: activeAccount.pubkey);
      return pendingWelcomes;
    }
  }

  wnWelcomesApi.Welcome? getWelcomeById(String welcomeId) {
    return state.welcomeById?[welcomeId];
  }

  void clearWelcome() {
    state = const wnWelcomeStateApi.WelcomeState();
  }

  Future<void> refreshWelcomes() async {
    await loadWelcomes();
  }

  /// Trigger callback for a specific welcome invitation
  /// TOTO pepi: trigger welcome callback if a welcome is pending
  // void triggerWelcomeCallback(wnWelcomesApi.Welcome welcomeData) {
  //   if (_onNewWelcomeCallback != null && welcomeData.state == wnWelcomesApi.wnWelcomeStateApi.WelcomeState.pending) {
  //     _logger.info('WelcomesProvider: Triggering callback for welcome ${welcomeData.id}');
  //     _onNewWelcomeCallback!(welcomeData);
  //   }
  // }

  /// Clear the callback
  void clearOnNewWelcomeCallback() {
    _onNewWelcomeCallback = null;
  }

  /// TODO big plans: Check for new welcomes and add them incrementally (for polling)
  // Future<void> checkForNewWelcomes() async {
  //   if (!_isAuthAvailable()) {
  //     return;
  //   }

  //   try {
  //     final activeAccountData =
  //         await ref.read(activeAccountProvider.notifier).getActiveAccount();
  //     if (activeAccountData == null) {
  //       return;
  //     }

  //     final newWelcomes = await wnWelcomesApi.pendingWelcomes(pubkey: activeAccountData.pubkey);

  //     final currentWelcomes = state.welcomes ?? [];
  //     final currentWelcomeIds = currentWelcomes.map((w) => w.id).toSet();

  //     // Find truly new welcomes
  //     final actuallyNewWelcomes =
  //         newWelcomes.where((welcome) => !currentWelcomeIds.contains(welcome.id)).toList();

  //     if (actuallyNewWelcomes.isNotEmpty) {
  //       // Add new welcomes to existing list
  //       final updatedWelcomes = [...currentWelcomes, ...actuallyNewWelcomes];

  //       // Update welcomeById map
  //       final welcomeByData = Map<String, wnWelcomesApi.Welcome>.from(state.welcomeById ?? {});
  //       for (final welcome in actuallyNewWelcomes) {
  //         welcomeByData[welcome.id] = welcome;
  //       }

  //       state = state.copyWith(
  //         welcomes: updatedWelcomes,
  //         welcomeById: welcomeByData,
  //       );

  //       final newPendingWelcomes = await wnWelcomesApi.pendingWelcomes(pubkey: activeAccountData.pubkey);
  //       if (newPendingWelcomes.isNotEmpty && _onNewWelcomeCallback != null) {
  //         _logger.info('WelcomesProvider: Found ${newPendingWelcomes.length} new pending welcomes');
  //         _onNewWelcomeCallback!(newPendingWelcomes.first);
  //       }

  //       _logger.info('WelcomesProvider: Added ${actuallyNewWelcomes.length} new welcomes');
  //     }
  //   } catch (e, st) {
  //     _logger.severe('WelcomesProvider.checkForNewWelcomes', e, st);
  //   }
  // }
}

final welcomesProvider = NotifierProvider<WelcomesNotifier, wnWelcomeStateApi.WelcomeState>(
  WelcomesNotifier.new,
);
