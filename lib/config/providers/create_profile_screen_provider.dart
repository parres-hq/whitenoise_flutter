// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'package:whitenoise/config/extensions/toast_extension.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/routing/router_provider.dart';
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;

class CreateProfileScreenState {
  final bool isLoading;
  final String? selectedImagePath;

  const CreateProfileScreenState({
    this.isLoading = false,
    this.selectedImagePath,
  });

  CreateProfileScreenState copyWith({
    bool? isLoading,
    String? selectedImagePath,
    bool clearSelectedImagePath = false,
  }) => CreateProfileScreenState(
    isLoading: isLoading ?? this.isLoading,
    selectedImagePath:
        clearSelectedImagePath ? null : (selectedImagePath ?? this.selectedImagePath),
  );
}

class CreateProfileScreenNotifier extends Notifier<CreateProfileScreenState> {
  final _logger = Logger('CreateProfileScreenNotifier');
  static final _imagePickerService = ImagePickerService();

  @override
  CreateProfileScreenState build() {
    return const CreateProfileScreenState();
  }

  Future<void> updateProfile(WidgetRef ref, String displayName, String bio) async {
    if (displayName.isEmpty) {
      ref.showRawErrorToast('Please enter a name');
      return;
    }

    String? profilePictureUrl;
    state = state.copyWith(isLoading: true);
    final profilePicPath = state.selectedImagePath;
    final activeAccountNotifier = ref.read(activeAccountProvider.notifier);
    final activeAccountState = await ref.read(activeAccountProvider.future);
    final activeAccount = activeAccountState.account;
    final initialMetadata = activeAccountState.metadata;

    if (activeAccount == null) {
      ref.showRawErrorToast('No active account found');
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      if (initialMetadata != null) {
        final isDisplayNameChanged =
            displayName.isNotEmpty && displayName != initialMetadata.displayName;
        final isBioProvided = bio.isNotEmpty;

        if (!isDisplayNameChanged && !isBioProvided && profilePicPath == null) {
          ref.read(routerProvider).go('/chats');
          return;
        }

        if (profilePicPath != null) {
          profilePictureUrl = await activeAccountNotifier.uploadProfilePicture(
            filePath: profilePicPath,
          );
        }

        final newMetadata = FlutterMetadata(
          name: initialMetadata.name,
          displayName: isDisplayNameChanged ? displayName : initialMetadata.displayName,
          about: isBioProvided ? bio : initialMetadata.about,
          picture: profilePictureUrl ?? initialMetadata.picture,
          banner: initialMetadata.banner,
          website: initialMetadata.website,
          nip05: initialMetadata.nip05,
          lud06: initialMetadata.lud06,
          lud16: initialMetadata.lud16,
          custom: initialMetadata.custom,
        );

        await activeAccountNotifier.updateMetadata(metadata: newMetadata);
        ref.read(routerProvider).go('/chats');
      }
    } catch (e, st) {
      _logger.severe('updateMetadata', e, st);
      ref.showRawErrorToast('Failed to update profile: $e');
    } finally {
      state = state.copyWith(isLoading: false, clearSelectedImagePath: true);
    }
  }

  Future<void> pickProfileImage(WidgetRef ref) async {
    try {
      final imagePath = await _imagePickerService.pickProfileImage();

      if (imagePath != null) {
        state = state.copyWith(selectedImagePath: imagePath);
      }
    } catch (e) {
      ref.showRawErrorToast('Failed to pick image: $e');
    }
  }
}

final createProfileScreenProvider =
    NotifierProvider<CreateProfileScreenNotifier, CreateProfileScreenState>(
      CreateProfileScreenNotifier.new,
    );
