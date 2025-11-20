import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/states/create_group_state.dart';
import 'package:whitenoise/domain/models/user_profile.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/api/utils.dart' as rust_utils;
import 'package:whitenoise/utils/error_handling.dart';

class CreateGroupNotifier extends StateNotifier<CreateGroupState> {
  final _logger = Logger('CreateGroupNotifier');
  static final _imagePickerService = ImagePickerService();
  final Ref ref;

  CreateGroupNotifier(this.ref) : super(const CreateGroupState());

  void updateGroupName(String groupName) {
    final isValid = groupName.trim().isNotEmpty;
    state = state.copyWith(
      groupName: groupName,
      isGroupNameValid: isValid,
      error: null,
    );
  }

  void updateGroupDescription(String groupDescription) {
    state = state.copyWith(
      groupDescription: groupDescription,
      error: null,
    );
  }

  Future<void> pickGroupImage() async {
    try {
      final imagePath = await _imagePickerService.pickProfileImage();
      if (imagePath != null) {
        state = state.copyWith(
          selectedImagePath: imagePath,
          error: null,
        );
      }
    } catch (e, st) {
      _logger.severe('pickGroupImage', e, st);
      state = state.copyWith(
        error: 'Failed to pick group image',
      );
    }
  }

  Future<void> filterUserProfilesWithKeyPackage(
    List<UserProfile> selectedUserProfiles,
  ) async {
    try {
      final filteredUserProfiles = await _filterUserProfilesByKeyPackage(selectedUserProfiles);
      final userProfilesWithKeyPackage = filteredUserProfiles['withKeyPackage']!;
      final userProfilesWithoutKeyPackage = filteredUserProfiles['withoutKeyPackage']!;

      state = state.copyWith(
        userProfilesWithKeyPackage: userProfilesWithKeyPackage,
        userProfilesWithoutKeyPackage: userProfilesWithoutKeyPackage,
        shouldShowInviteSheet: userProfilesWithoutKeyPackage.isNotEmpty,
      );

      if (userProfilesWithKeyPackage.isEmpty) {
        state = state.copyWith(isCreatingGroup: false);
        return;
      }
    } catch (e, st) {
      _logger.severe('filterUserProfilesWithKeyPackage', e, st);
      state = state.copyWith(
        error: 'Error filtering userProfiles: ${e.toString()}',
        isCreatingGroup: false,
      );
    }
  }

  Future<void> createGroup({
    ValueChanged<Group?>? onGroupCreated,
  }) async {
    if (!state.isGroupNameValid) return;
    if (state.userProfilesWithKeyPackage.isEmpty) return;

    state = state.copyWith(isCreatingGroup: true, error: null);

    try {
      final createdGroup = await _createGroupWithUserProfiles(state.userProfilesWithKeyPackage);

      if (createdGroup != null) {
        if (state.selectedImagePath != null && state.selectedImagePath!.isNotEmpty) {
          final activePubkey = ref.read(activePubkeyProvider) ?? '';
          if (activePubkey.isEmpty) {
            throw Exception('No active pubkey available');
          }

          final uploadResult = await _uploadGroupImage(
            createdGroup.mlsGroupId,
            activePubkey,
          );

          if (uploadResult != null) {
            await createdGroup.updateGroupData(
              accountPubkey: activePubkey,
              groupData: FlutterGroupDataUpdate(
                imageKey: uploadResult.imageKey,
                imageHash: uploadResult.encryptedHash,
                imageNonce: uploadResult.imageNonce,
              ),
            );

            // Reload the image path after uploading
            await ref.read(groupsProvider.notifier).reloadGroupImagePath(createdGroup.mlsGroupId);
          }
        }

        onGroupCreated?.call(createdGroup);

        state = state.copyWith(
          isCreatingGroup: false,
          shouldShowInviteSheet: false,
          userProfilesWithoutKeyPackage: [],
        );
      } else {
        state = state.copyWith(
          error: _getDetailedGroupCreationError(),
          isCreatingGroup: false,
        );
      }
    } catch (e, st) {
      _logger.severe('createGroup', e, st);
      final fallbackMessage = ErrorHandlingUtils.getGroupCreationFallbackMessage();
      final errorMessage = await ErrorHandlingUtils.convertErrorToUserFriendlyMessage(
        error: e,
        stackTrace: st,
        fallbackMessage: fallbackMessage,
        context: 'CreateGroupNotifier.createGroup',
      );

      state = state.copyWith(
        error: errorMessage,
        isCreatingGroup: false,
      );
    }
  }

  Future<Group?> _createGroupWithUserProfiles(List<UserProfile> userProfilesWithKeyPackage) async {
    final groupName = state.groupName.trim();
    final groupDescription = state.groupDescription.trim();
    final notifier = ref.read(groupsProvider.notifier);

    return await notifier.createNewGroup(
      groupName: groupName,
      groupDescription: groupDescription,
      memberPublicKeyHexs: userProfilesWithKeyPackage.map((c) => c.publicKey).toList(),
      adminPublicKeyHexs: [],
    );
  }

  String _getDetailedGroupCreationError() {
    final groupsState = ref.read(groupsProvider);
    final fallbackMessage = ErrorHandlingUtils.getGroupCreationFallbackMessage();
    final providerError = groupsState.error?.trim();
    if (providerError != null && providerError.isNotEmpty) {
      return providerError;
    }
    return fallbackMessage;
  }

  Future<UploadGroupImageResult?> _uploadGroupImage(String groupId, String accountPubkey) async {
    if (state.selectedImagePath == null || state.selectedImagePath!.isEmpty) return null;

    state = state.copyWith(isUploadingImage: true, error: null);

    try {
      final serverUrl = await rust_utils.getDefaultBlossomServerUrl();

      final result = await uploadGroupImage(
        accountPubkey: accountPubkey,
        groupId: groupId,
        filePath: state.selectedImagePath!,
        serverUrl: serverUrl,
      );

      state = state.copyWith(
        isUploadingImage: false,
        error: null,
      );
      return result;
    } catch (e, st) {
      _logger.severe('_uploadGroupImage', e, st);
      state = state.copyWith(
        error: 'Failed to upload group image: ${e.toString()}',
        isUploadingImage: false,
      );
    }
    return null;
  }

  Future<Map<String, List<UserProfile>>> _filterUserProfilesByKeyPackage(
    List<UserProfile> userProfiles,
  ) async {
    final userProfilesWithKeyPackage = <UserProfile>[];
    final userProfilesWithoutKeyPackage = <UserProfile>[];

    for (final userProfile in userProfiles) {
      try {
        final hasKeyPackage = await userHasKeyPackage(
          pubkey: userProfile.publicKey,
          blockingDataSync: true,
        );

        if (hasKeyPackage) {
          userProfilesWithKeyPackage.add(userProfile);
        } else {
          userProfilesWithoutKeyPackage.add(userProfile);
        }
      } catch (e) {
        userProfilesWithoutKeyPackage.add(userProfile);
      }
    }

    return {
      'withKeyPackage': userProfilesWithKeyPackage,
      'withoutKeyPackage': userProfilesWithoutKeyPackage,
    };
  }

  void clearError() {
    state = state.copyWith(
      error: null,
    );
  }

  void dismissInviteSheet() {
    state = state.copyWith(
      shouldShowInviteSheet: false,
      userProfilesWithoutKeyPackage: [],
    );
  }

  void discardChanges() {
    state = state.copyWith(
      groupName: '',
      groupDescription: '',
      isGroupNameValid: false,
      isCreatingGroup: false,
      isUploadingImage: false,
      selectedImagePath: null,
      error: null,
      userProfilesWithKeyPackage: [],
      userProfilesWithoutKeyPackage: [],
      shouldShowInviteSheet: false,
    );
  }
}

final createGroupProvider = StateNotifierProvider<CreateGroupNotifier, CreateGroupState>(
  CreateGroupNotifier.new,
);
