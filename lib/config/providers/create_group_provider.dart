import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/states/create_group_state.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/api/utils.dart' as rust_utils;
import 'package:whitenoise/utils/localization_extensions.dart';

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

  Future<void> filterContactsWithKeyPackage(
    List<ContactModel> selectedContacts,
  ) async {
    try {
      final filteredContacts = await _filterContactsByKeyPackage(selectedContacts);
      final contactsWithKeyPackage = filteredContacts['withKeyPackage']!;
      final contactsWithoutKeyPackage = filteredContacts['withoutKeyPackage']!;

      state = state.copyWith(
        contactsWithKeyPackage: contactsWithKeyPackage,
        contactsWithoutKeyPackage: contactsWithoutKeyPackage,
        shouldShowInviteSheet: contactsWithoutKeyPackage.isNotEmpty,
      );

      if (contactsWithKeyPackage.isEmpty) {
        state = state.copyWith(isCreatingGroup: false);
        return;
      }
    } catch (e, st) {
      _logger.severe('filterContactsWithKeyPackage', e, st);
      state = state.copyWith(
        error: 'Error filtering contacts: ${e.toString()}',
        isCreatingGroup: false,
      );
    }
  }

  Future<void> createGroup({
    ValueChanged<Group?>? onGroupCreated,
  }) async {
    if (!state.isGroupNameValid) return;
    if (state.contactsWithKeyPackage.isEmpty) return;

    state = state.copyWith(isCreatingGroup: true, error: null);

    try {
      final createdGroup = await _createGroupWithContacts(state.contactsWithKeyPackage);

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
          }
        }

        onGroupCreated?.call(createdGroup);

        state = state.copyWith(
          isCreatingGroup: false,
          shouldShowInviteSheet: false,
          contactsWithoutKeyPackage: [],
        );
      } else {
        state = state.copyWith(
          error: 'ui.failedToCreateGroup'.tr(),
          isCreatingGroup: false,
        );
      }
    } catch (e, st) {
      _logger.severe('createGroup', e, st);
      state = state.copyWith(
        error: 'ui.errorCreatingGroup'.tr(),
        isCreatingGroup: false,
      );
    }
  }

  Future<Group?> _createGroupWithContacts(List<ContactModel> contactsWithKeyPackage) async {
    final groupName = state.groupName.trim();
    final groupDescription = state.groupDescription.trim();
    final notifier = ref.read(groupsProvider.notifier);

    return await notifier.createNewGroup(
      groupName: groupName,
      groupDescription: groupDescription,
      memberPublicKeyHexs: contactsWithKeyPackage.map((c) => c.publicKey).toList(),
      adminPublicKeyHexs: [],
    );
  }

  Future<UploadGroupImageResult?> _uploadGroupImage(String groupId, String accountPubkey) async {
    if (state.selectedImagePath == null || state.selectedImagePath!.isEmpty) return null;

    state = state.copyWith(isUploadingImage: true, error: null);

    try {
      final imageUtils = ref.read(wnImageUtilsProvider);
      final imageType = await imageUtils.getMimeTypeFromPath(state.selectedImagePath!);
      if (imageType == null) {
        throw Exception(
          'Could not determine image type from file path: ${state.selectedImagePath}',
        );
      }

      final serverUrl = await rust_utils.getDefaultBlossomServerUrl();

      final result = await uploadGroupImage(
        accountPubkey: accountPubkey,
        groupId: groupId,
        filePath: state.selectedImagePath!,
        imageType: imageType,
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

  Future<Map<String, List<ContactModel>>> _filterContactsByKeyPackage(
    List<ContactModel> contacts,
  ) async {
    final contactsWithKeyPackage = <ContactModel>[];
    final contactsWithoutKeyPackage = <ContactModel>[];

    for (final contact in contacts) {
      try {
        final hasKeyPackage = await userHasKeyPackage(pubkey: contact.publicKey);

        if (hasKeyPackage) {
          contactsWithKeyPackage.add(contact);
        } else {
          contactsWithoutKeyPackage.add(contact);
        }
      } catch (e) {
        contactsWithoutKeyPackage.add(contact);
      }
    }

    return {
      'withKeyPackage': contactsWithKeyPackage,
      'withoutKeyPackage': contactsWithoutKeyPackage,
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
      contactsWithoutKeyPackage: [],
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
      contactsWithKeyPackage: [],
      contactsWithoutKeyPackage: [],
      shouldShowInviteSheet: false,
    );
  }
}

final createGroupProvider = StateNotifierProvider<CreateGroupNotifier, CreateGroupState>(
  CreateGroupNotifier.new,
);
