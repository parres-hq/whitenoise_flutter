import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/domain/models/user_profile.dart';

part 'create_group_state.freezed.dart';

@freezed
sealed class CreateGroupState with _$CreateGroupState {
  const factory CreateGroupState({
    @Default('') String groupName,
    @Default('') String groupDescription,
    @Default(false) bool isGroupNameValid,
    @Default(false) bool isCreatingGroup,
    @Default(false) bool isUploadingImage,
    String? selectedImagePath,
    String? error,
    @Default([]) List<UserProfile> userProfilesWithoutKeyPackage,
    @Default([]) List<UserProfile> userProfilesWithKeyPackage,
    @Default(false) bool shouldShowInviteSheet,
  }) = _CreateGroupState;

  const CreateGroupState._();

  bool get canCreateGroup =>
      isGroupNameValid &&
      !isCreatingGroup &&
      !isUploadingImage &&
      userProfilesWithKeyPackage.isNotEmpty;
}
