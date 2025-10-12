import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/domain/models/contact_model.dart';

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
    @Default([]) List<ContactModel> contactsWithoutKeyPackage,
    @Default([]) List<ContactModel> contactsWithKeyPackage,
    @Default(false) bool shouldShowInviteSheet,
  }) = _CreateGroupState;

  const CreateGroupState._();

  bool get canCreateGroup =>
      isGroupNameValid &&
      !isCreatingGroup &&
      !isUploadingImage &&
      contactsWithKeyPackage.isNotEmpty;
}
