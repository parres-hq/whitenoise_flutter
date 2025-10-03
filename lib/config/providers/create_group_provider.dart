import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/states/create_group_state.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/src/rust/api/groups.dart';
import 'package:whitenoise/src/rust/api/users.dart';
import 'package:whitenoise/src/rust/api/utils.dart' as rust_utils;
import 'package:whitenoise/utils/image_utils.dart';

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
      stackTrace: null,
    );
  }

  Future<void> pickGroupImage() async {
    try {
      final imagePath = await _imagePickerService.pickProfileImage();
      if (imagePath != null) {
        state = state.copyWith(
          selectedImagePath: imagePath,
          error: null,
          stackTrace: null,
        );
      }
    } catch (e, st) {
      _logger.severe('pickGroupImage', e, st);
      state = state.copyWith(
        error: 'Failed to pick group image',
        stackTrace: st,
      );
    }
  }

  Future<void> filterContactsAndCreateGroup({
    required List<ContactModel> selectedContacts,
    ValueChanged<Group?>? onGroupCreated,
  }) async {
    if (!state.isGroupNameValid) return;

    state = state.copyWith(isCreatingGroup: true, error: null, stackTrace: null);

    try {
      final filteredContacts = await _filterContactsByKeyPackage(selectedContacts);
      final contactsWithKeyPackage = filteredContacts['withKeyPackage']!;
      final contactsWithoutKeyPackage = filteredContacts['withoutKeyPackage']!;

      state = state.copyWith(
        contactsWithoutKeyPackage: contactsWithoutKeyPackage,
        shouldShowInviteSheet: contactsWithoutKeyPackage.isNotEmpty,
      );

      if (contactsWithKeyPackage.isEmpty) {
        state = state.copyWith(isCreatingGroup: false);
        return;
      }

      final createdGroup = await _createGroupWithContacts(contactsWithKeyPackage);

      if (createdGroup != null) {
        if (state.selectedImagePath != null && state.selectedImagePath!.isNotEmpty) {
          await _uploadGroupImage(createdGroup.mlsGroupId);
        }

        onGroupCreated?.call(createdGroup);

        state = state.copyWith(
          isCreatingGroup: false,
          shouldShowInviteSheet: false,
          contactsWithoutKeyPackage: [],
        );
      } else {
        state = state.copyWith(
          error: 'Failed to create group chat. Please try again.',
          isCreatingGroup: false,
        );
      }
    } catch (e, st) {
      _logger.severe('filterContactsAndCreateGroup', e, st);
      state = state.copyWith(
        error: 'Error creating group: ${e.toString()}',
        stackTrace: st,
        isCreatingGroup: false,
      );
    }
  }

  Future<Group?> _createGroupWithContacts(List<ContactModel> contactsWithKeyPackage) async {
    final groupName = state.groupName.trim();
    final notifier = ref.read(groupsProvider.notifier);

    return await notifier.createNewGroup(
      groupName: groupName,
      groupDescription: '',
      memberPublicKeyHexs: contactsWithKeyPackage.map((c) => c.publicKey).toList(),
      adminPublicKeyHexs: [],
    );
  }

  Future<void> _uploadGroupImage(String groupId) async {
    if (state.selectedImagePath == null || state.selectedImagePath!.isEmpty) return;

    state = state.copyWith(isUploadingImage: true, error: null, stackTrace: null);

    try {
      final activePubkey = ref.read(activePubkeyProvider);
      if (activePubkey == null || activePubkey.isEmpty) {
        throw Exception('No active pubkey available');
      }

      final imageType = await ImageUtils.getMimeTypeFromPath(state.selectedImagePath!);
      if (imageType == null) {
        throw Exception(
          'Could not determine image type from file path: ${state.selectedImagePath}',
        );
      }

      final serverUrl = await rust_utils.getDefaultBlossomServerUrl();

      await uploadGroupImage(
        accountPubkey: activePubkey,
        groupId: groupId,
        filePath: state.selectedImagePath!,
        imageType: imageType,
        serverUrl: serverUrl,
      );

      state = state.copyWith(
        isUploadingImage: false,
        error: null,
        stackTrace: null,
      );
    } catch (e, st) {
      _logger.severe('_uploadGroupImage', e, st);
      state = state.copyWith(
        error: 'Failed to upload group image: ${e.toString()}',
        stackTrace: st,
        isUploadingImage: false,
      );
    }
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
    state = state.copyWith(error: null, stackTrace: null);
  }

  void dismissInviteSheet() {
    state = state.copyWith(
      shouldShowInviteSheet: false,
      contactsWithoutKeyPackage: [],
    );
  }
}

final createGroupProvider = StateNotifierProvider<CreateGroupNotifier, CreateGroupState>(
  CreateGroupNotifier.new,
);
