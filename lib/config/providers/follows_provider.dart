import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/utils/error_handling.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';
import 'package:whitenoise/utils/user_utils.dart';

class FollowsState {
  final List<User> follows;
  final bool isLoading;
  final String? error;

  const FollowsState({
    this.follows = const [],
    this.isLoading = false,
    this.error,
  });

  FollowsState copyWith({
    List<User>? follows,
    bool? isLoading,
    String? error,
  }) {
    return FollowsState(
      follows: follows ?? this.follows,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class FollowsNotifier extends Notifier<FollowsState> {
  final _logger = Logger('FollowsNotifier');

  @override
  FollowsState build() {
    ref.listen<String?>(activePubkeyProvider, (previous, next) {
      if (previous != null && next != null && previous != next) {
        Future.microtask(() {
          clearFollows();
          loadFollows();
        });
      } else if (previous != null && next == null) {
        Future.microtask(() {
          clearFollows();
        });
      } else if (previous == null && next != null) {
        Future.microtask(() {
          loadFollows();
        });
      }
    });

    return const FollowsState();
  }

  bool _isAuthAvailable() {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = state.copyWith(error: 'Not authenticated');
      return false;
    }
    return true;
  }

  Future<void> loadFollows() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    if (!_isAuthAvailable()) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final activePubkey = ref.read(activePubkeyProvider) ?? '';
      if (activePubkey.isEmpty) {
        state = state.copyWith(error: 'No active account found', isLoading: false);
        return;
      }

      final follows = await accounts_api.accountFollows(pubkey: activePubkey);

      _logger.info('FollowsProvider: Loaded ${follows.length} follows');

      final sortedFollows = UserUtils.sortUsersByName(follows);

      state = state.copyWith(follows: sortedFollows, isLoading: false);
    } catch (e, st) {
      _logger.severe('FollowsProvider.loadFollows - Exception: $e (Type: ${e.runtimeType})', e, st);

      final errorMessage = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage:
            'Failed to load follows due to an internal error. Please check your connection and try again.',
        context: 'loadFollows',
      );

      state = state.copyWith(error: errorMessage, isLoading: false);
    }
  }

  void clearFollows() {
    state = const FollowsState();
  }

  List<User> getFilteredFollows(String searchQuery) {
    return UserUtils.filterUsers(state.follows, searchQuery);
  }

  User? findFollowByPubkey(String pubkey) {
    return state.follows.where((user) => user.pubkey == pubkey).firstOrNull;
  }

  bool isFollowing(String pubkey) {
    final hexPubkey = PubkeyFormatter(pubkey: pubkey).toHex();
    if (hexPubkey == null) return false;
    return state.follows.any((user) => PubkeyFormatter(pubkey: user.pubkey).toHex() == hexPubkey);
  }

  List<User> get allFollows => state.follows;
}

final followsProvider = NotifierProvider<FollowsNotifier, FollowsState>(
  FollowsNotifier.new,
);
