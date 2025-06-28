import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';

const String _profileReadyCardDismissedKey = 'profile_ready_card_dismissed';

final profileReadyCardVisibilityProvider =
    AsyncNotifierProvider<ProfileReadyCardVisibilityNotifier, bool>(
      ProfileReadyCardVisibilityNotifier.new,
    );

class ProfileReadyCardVisibilityNotifier extends AsyncNotifier<bool> {
  late final SharedPreferences _prefs;
  String? _currentPubKey;

  @override
  Future<bool> build() async {
    _prefs = await SharedPreferences.getInstance();
    final activeAccountPubkey = ref.watch(activeAccountProvider);
    _currentPubKey = activeAccountPubkey;
    return await _loadVisibilityState();
  }

  Future<bool> _loadVisibilityState() async {
    try {
      if (_currentPubKey == null || _currentPubKey!.isEmpty) {
        return true;
      }

      final isDismissed =
          _prefs.getBool('${_profileReadyCardDismissedKey}_$_currentPubKey') ?? false;
      return !isDismissed;
    } catch (e) {
      return true;
    }
  }

  Future<void> dismissCard() async {
    try {
      if (_currentPubKey == null || _currentPubKey!.isEmpty) {
        state = const AsyncValue.data(false);
        return;
      }

      await _prefs.setBool('${_profileReadyCardDismissedKey}_$_currentPubKey', true);
      state = const AsyncValue.data(false);
    } catch (e) {
      state = const AsyncValue.data(false);
    }
  }

  Future<void> resetVisibility() async {
    try {
      if (_currentPubKey == null || _currentPubKey!.isEmpty) {
        state = const AsyncValue.data(true);
        return;
      }

      await _prefs.remove('${_profileReadyCardDismissedKey}_$_currentPubKey');
      state = const AsyncValue.data(true);
    } catch (e) {
      state = const AsyncValue.data(true);
    }
  }
}
