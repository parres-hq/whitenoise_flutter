import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/follows_provider.dart';
import 'package:whitenoise/src/rust/api/accounts.dart' as accounts_api;

class FollowState {
  final bool isFollowing;
  final bool isLoading;
  final String? error;

  const FollowState({
    this.isFollowing = false,
    this.isLoading = false,
    this.error,
  });

  FollowState copyWith({
    bool? isFollowing,
    bool? isLoading,
    String? error,
  }) {
    return FollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FollowNotifier extends FamilyNotifier<FollowState, String> {
  final _logger = Logger('FollowNotifier');

  @override
  FollowState build(String pubkey) {
    ref.listen<String?>(activePubkeyProvider, (previous, next) {
      if (previous != next) {
        ref.invalidateSelf();
      }
    });

    final followsNotifier = ref.read(followsProvider.notifier);
    final isFollowing = followsNotifier.isFollowing(pubkey);

    return FollowState(isFollowing: isFollowing);
  }

  bool isFollow(String pubkey) {
    return state.isFollowing;
  }

  Future<void> addFollow(String pubkey) async {
    final activePubkey = ref.read(activePubkeyProvider);
    if (activePubkey == null) {
      state = state.copyWith(error: 'No active account found');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      await accounts_api.followUser(
        accountPubkey: activePubkey,
        userToFollowPubkey: pubkey,
      );
      await ref.read(followsProvider.notifier).loadFollows();
      state = state.copyWith(isFollowing: true, isLoading: false);

      _logger.info('Successfully followed user: $pubkey');
    } catch (e) {
      _logger.severe('Failed to follow user: $e');
      state = state.copyWith(error: 'Failed to follow user', isLoading: false);
    }
  }

  Future<void> removeFollow(String pubkey) async {
    final activePubkey = ref.read(activePubkeyProvider);
    if (activePubkey == null) {
      state = state.copyWith(error: 'No active account found');
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      await accounts_api.unfollowUser(
        accountPubkey: activePubkey,
        userToUnfollowPubkey: pubkey,
      );
      await ref.read(followsProvider.notifier).loadFollows();
      state = state.copyWith(isFollowing: false, isLoading: false);

      _logger.info('Successfully unfollowed user: $pubkey');
    } catch (e) {
      _logger.severe('Failed to unfollow user: $e');
      state = state.copyWith(error: 'Failed to unfollow user', isLoading: false);
    }
  }
}

final followProvider = NotifierProvider.family<FollowNotifier, FollowState, String>(
  FollowNotifier.new,
);
