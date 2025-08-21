import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/groups.dart';

part 'group_state.freezed.dart';

@freezed
abstract class GroupsState with _$GroupsState {
  const factory GroupsState({
    List<Group>? groups,
    Map<String, Group>? groupsMap, // groupId -> GroupData
    Map<String, List<User>>? groupMembers, // groupId -> members
    Map<String, List<User>>? groupAdmins, // groupId -> admins
    Map<String, String>? groupDisplayNames, // groupId -> display name
    @Default(false) bool isLoading,
    String? error,
  }) = _GroupsState;
}
