import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/user_profile_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' as domain_user;
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/src/rust/api/groups.dart' as groups_api;
import 'package:whitenoise/src/rust/api/messages.dart'
    show ChatMessage, fetchAggregatedMessagesForGroup;
import 'package:whitenoise/utils/message_converter.dart';
import 'package:whitenoise/utils/pubkey_utils.dart';

class GroupMessagesState {
  final String groupId;

  const GroupMessagesState({
    required this.groupId,
  });
}

class GroupMessagesNotifier extends FamilyNotifier<GroupMessagesState, String> {
  late final Future<List<ChatMessage>> Function({
    required String pubkey,
    required String groupId,
  })
  _fetchAggregatedMessagesForGroup;

  late final Future<List<String>> Function({
    required String pubkey,
    required String groupId,
  })
  _groupMembers;

  late final bool Function({required String myPubkey, required String otherPubkey}) _isMe;

  GroupMessagesNotifier({
    Future<List<ChatMessage>> Function({
      required String pubkey,
      required String groupId,
    })?
    fetchAggregatedMessagesForGroupFn,
    Future<List<String>> Function({
      required String pubkey,
      required String groupId,
    })?
    groupMembersFn,
    bool Function({required String myPubkey, required String otherPubkey})? isMeFn,
  }) {
    _fetchAggregatedMessagesForGroup =
        fetchAggregatedMessagesForGroupFn ?? fetchAggregatedMessagesForGroup;
    _groupMembers = groupMembersFn ?? groups_api.groupMembers;
    _isMe = isMeFn ?? PubkeyUtils.isMe;
  }

  @override
  GroupMessagesState build(String groupId) {
    return GroupMessagesState(
      groupId: groupId,
    );
  }

  Future<List<MessageModel>> fetchMessages() async {
    final activePubkey = ref.read(activePubkeyProvider);
    if (activePubkey == null || activePubkey.isEmpty) {
      return [];
    }
    final chatMessages = await _fetchAggregatedMessagesForGroup(
      pubkey: activePubkey,
      groupId: state.groupId,
    );

    chatMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _toMessageModels(chatMessages: chatMessages, activePubkey: activePubkey);
  }

  Future<List<MessageModel>> _toMessageModels({
    required List<ChatMessage> chatMessages,
    required String activePubkey,
  }) async {
    final usersMap = await _fetchGroupUsersMap();
    final messages = MessageConverter.fromChatMessageList(
      chatMessages,
      currentUserPublicKey: activePubkey,
      groupId: state.groupId,
      usersMap: usersMap,
    );
    return messages;
  }

  Future<Map<String, domain_user.User>> _fetchGroupUsersMap() async {
    final activePubkey = ref.read(activePubkeyProvider);
    if (activePubkey == null || activePubkey.isEmpty) {
      return {};
    }
    final groupUserProfiles = await _fetchGroupUserProfiles(activePubkey);
    final domainUsersMap = _mapUserProfilesToDomainUsers(
      activePubkey: activePubkey,
      userProfiles: groupUserProfiles,
    );
    return domainUsersMap;
  }

  Future<List<MapEntry<String, UserProfile>>> _fetchUserProfiles(
    List<String> pubkeys,
  ) async {
    final userProfileNotifier = ref.read(userProfileProvider.notifier);
    final userFutures = pubkeys.map(
      (pubkey) => userProfileNotifier
          .getUserProfile(pubkey)
          .then((userProfile) => MapEntry(pubkey, userProfile)),
    );
    final usersProfileData = await Future.wait(userFutures);
    return usersProfileData;
  }

  Future<List<MapEntry<String, UserProfile>>> _fetchGroupUserProfiles(
    String activePubkey,
  ) async {
    final groupMembersPubkeys = await _groupMembers(
      pubkey: activePubkey,
      groupId: state.groupId,
    );
    final groupMembersUserProfile = await _fetchUserProfiles(groupMembersPubkeys);
    return groupMembersUserProfile;
  }

  Map<String, domain_user.User> _mapUserProfilesToDomainUsers({
    required String activePubkey,
    required List<MapEntry<String, UserProfile>> userProfiles,
  }) {
    return Map<String, domain_user.User>.fromEntries(
      userProfiles.map(
        (entry) => MapEntry(
          entry.key,
          _userProfileToDomainUser(activePubkey: activePubkey, userProfile: entry.value),
        ),
      ),
    );
  }

  String _getDisplayName({
    required String activePubkey,
    required UserProfile userProfile,
  }) {
    if (_isMe(myPubkey: activePubkey, otherPubkey: userProfile.publicKey)) {
      return 'You';
    } else {
      return userProfile.displayName;
    }
  }

  domain_user.User _userProfileToDomainUser({
    required String activePubkey,
    required UserProfile userProfile,
  }) {
    return domain_user.User(
      id: userProfile.publicKey,
      displayName: _getDisplayName(activePubkey: activePubkey, userProfile: userProfile),
      nip05: userProfile.nip05 ?? '',
      publicKey: userProfile.publicKey,
      imagePath: userProfile.imagePath,
    );
  }
}

final groupMessagesProvider =
    NotifierProvider.family<GroupMessagesNotifier, GroupMessagesState, String>(
      () => GroupMessagesNotifier(),
    );
