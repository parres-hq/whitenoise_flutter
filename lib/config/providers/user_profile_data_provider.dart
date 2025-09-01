import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api/users.dart' as wn_users_api;
import 'package:whitenoise/src/rust/api/users.dart' show User;

abstract class WnUsersApi {
  Future<User> getUser({required String pubkey});
}

class DefaultWnUsersApi implements WnUsersApi {
  const DefaultWnUsersApi();

  @override
  Future<User> getUser({required String pubkey}) {
    return wn_users_api.getUser(pubkey: pubkey);
  }
}

class UserProfileDataNotifier extends Notifier<void> {
  final WnUsersApi _usersApi;

  UserProfileDataNotifier({WnUsersApi? usersApi})
    : _usersApi = usersApi ?? const DefaultWnUsersApi();

  @override
  void build() {}

  Future<ContactModel> getUserProfileData(String pubkey) async {
    final user = await _usersApi.getUser(pubkey: pubkey);
    final userProfileData = ContactModel.fromMetadata(
      publicKey: pubkey,
      metadata: user.metadata,
    );
    return userProfileData;
  }
}

final userProfileDataProvider = NotifierProvider<UserProfileDataNotifier, void>(
  UserProfileDataNotifier.new,
);
