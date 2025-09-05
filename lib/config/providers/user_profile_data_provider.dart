import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;
import 'package:whitenoise/src/rust/api/users.dart' as wn_users_api;
import 'package:whitenoise/src/rust/api/users.dart' show User;

class UserProfileDataNotifier extends Notifier<void> {
  late final Future<User> Function({required String pubkey}) _wnApiGetUser;
  late final ContactModel Function({required String pubkey, required FlutterMetadata metadata})
  _getContactModelFromMetadata;

  UserProfileDataNotifier({
    Future<User> Function({required String pubkey})? wnApiGetUserFn,
    ContactModel Function({required String pubkey, required FlutterMetadata metadata})?
    getContactModelFromMetadataFn,
  }) {
    _wnApiGetUser = wnApiGetUserFn ?? wn_users_api.getUser;
    _getContactModelFromMetadata = getContactModelFromMetadataFn ?? ContactModel.fromMetadata;
  }

  @override
  void build() {}

  Future<ContactModel> getUserProfileData(String pubkey) async {
    final user = await _wnApiGetUser(pubkey: pubkey);
    final userProfileData = _getContactModelFromMetadata(pubkey: pubkey, metadata: user.metadata);
    return userProfileData;
  }
}

final userProfileDataProvider = NotifierProvider<UserProfileDataNotifier, void>(
  () => UserProfileDataNotifier(),
);
