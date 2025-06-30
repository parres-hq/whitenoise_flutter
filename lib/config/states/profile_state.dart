import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    String? displayName,
    String? about,
    String? picture,
    String? nip05,
  }) = _ProfileState;

  const ProfileState._();
}
