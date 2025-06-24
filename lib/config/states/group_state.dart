import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/src/rust/api.dart';

part 'group_state.freezed.dart';

@freezed
abstract class GroupsState with _$GroupsState {
  const factory GroupsState({
    List<GroupData>? groups,
    Map<String, List<PublicKey>>? groupMembers, // groupId -> members
    Map<String, List<PublicKey>>? groupAdmins, // groupId -> admins
    @Default(false) bool isLoading,
    String? error,
  }) = _GroupsState;
}
