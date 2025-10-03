import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/src/rust/api/users.dart' as wn_users_api;
import 'package:whitenoise/src/rust/api/users.dart' show User;

class UserProfileNotifier extends Notifier<void> {
  late final Future<User> Function({required String pubkey}) _wnApiGetUser;
  late final UserProfile Function({required String pubkey, required FlutterMetadata metadata})
  _getUserProfileFromMetadata;

  UserProfileNotifier({
    Future<User> Function({required String pubkey})? wnApiGetUserFn,
    UserProfile Function({required String pubkey, required FlutterMetadata metadata})?
    getUserProfileFromMetadataFn,
  }) {
    _wnApiGetUser = wnApiGetUserFn ?? wn_users_api.getUser;
    _getUserProfileFromMetadata = getUserProfileFromMetadataFn ?? UserProfile.fromMetadata;
  }

  @override
  void build() {}

  Future<UserProfile> getUserProfile(String pubkey) async {
    final user = await _wnApiGetUser(pubkey: pubkey);
    final userProfile = _getUserProfileFromMetadata(pubkey: pubkey, metadata: user.metadata);
    return userProfile;
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, void>(
  () => UserProfileNotifier(),
);
