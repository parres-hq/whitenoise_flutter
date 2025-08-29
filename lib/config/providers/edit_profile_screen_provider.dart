import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/src/rust/api/error.dart' show ApiError;
import 'package:whitenoise/src/rust/api/metadata.dart' show FlutterMetadata;

class EditProfileScreenNotifier extends AsyncNotifier<ProfileState> {
  final _logger = Logger('EditProfileScreenNotifier');
  static final _imagePickerService = ImagePickerService();

  @override
  Future<ProfileState> build() async {
    return const ProfileState();
  }

  Future<void> fetchProfileData() async {
    state = const AsyncValue.loading();

    try {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        state = AsyncValue.error(
          'Not authenticated',
          StackTrace.current,
        );
        return;
      }

      final activeAccountState = await ref.read(activeAccountProvider.future);
      final activeAccount = activeAccountState.account;
      final metadata = activeAccountState.metadata;

      if (activeAccount == null) {
        state = AsyncValue.error('No active account found', StackTrace.current);
        return;
      }

      final profileState = ProfileState(
        displayName: metadata?.displayName,
        about: metadata?.about,
        picture: metadata?.picture,
        nip05: metadata?.nip05,
        selectedImagePath: '',
      );

      state = AsyncValue.data(
        profileState.copyWith(initialProfile: profileState),
      );
    } catch (e, st) {
      _logger.severe('loadProfileData', e, st);
      state = AsyncValue.error(e.toString(), st);
    } finally {
      final stateValue = state.value;
      if (stateValue != null) {
        state = AsyncValue.data(
          stateValue.copyWith(isSaving: false, stackTrace: null, error: null),
        );
      }
    }
  }

  void updateLocalProfile({
    String? displayName,
    String? about,
    String? picture,
    String? nip05,
  }) {
    state.whenData((value) {
      state = AsyncValue.data(
        value.copyWith(
          displayName: displayName ?? value.displayName,
          about: about ?? value.about,
          picture: picture ?? value.picture,
          nip05: nip05 ?? value.nip05,
        ),
      );
    });
  }

  void discardChanges() {
    state.whenData((value) {
      if (value.initialProfile != null) {
        state = AsyncValue.data(
          value.copyWith(
            displayName: value.initialProfile!.displayName,
            about: value.initialProfile!.about,
            picture: value.initialProfile!.picture,
            nip05: value.initialProfile!.nip05,
          ),
        );
      }
    });
  }

  Future<void> pickProfileImage() async {
    try {
      final imagePath = await _imagePickerService.pickProfileImage();

      if (imagePath != null) {
        state.whenData(
          (value) =>
              state = AsyncValue.data(
                value.copyWith(selectedImagePath: imagePath),
              ),
        );
      }
    } catch (e, st) {
      _logger.severe('pickProfileImage', e, st);
      state = AsyncValue.error('Failed to pick profile image', st);
    }
  }

  Future<void> updateProfileData() async {
    final previousState = state.asData?.value ?? const ProfileState();
    state = AsyncValue.data(previousState.copyWith(isSaving: true, error: null, stackTrace: null));

    try {
      String? profilePictureUrl;
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return;
      }

      final activeAccountState = await ref.read(activeAccountProvider.future);
      final activeAccount = activeAccountState.account;
      final initialMetadata = activeAccountState.metadata;

      if (activeAccount == null) {
        state = AsyncValue.error('No active account found', StackTrace.current);
        return;
      }

      if (initialMetadata == null) {
        throw Exception('Metadata not found');
      }

      final activeAccountNotifier = ref.read(activeAccountProvider.notifier);

      if ((state.value?.selectedImagePath?.isNotEmpty) ?? false) {
        profilePictureUrl = await activeAccountNotifier.uploadProfilePicture(
          filePath: state.value!.selectedImagePath!,
        );
      }

      final currentState = state.value!;
      final displayNameChanged =
          currentState.displayName != null &&
          currentState.displayName != initialMetadata.displayName;
      final aboutChanged =
          currentState.about != null && currentState.about != initialMetadata.about;
      final nip05Changed =
          currentState.nip05 != null && currentState.nip05 != initialMetadata.nip05;

      final newMetadata = FlutterMetadata(
        name: initialMetadata.name,
        displayName: displayNameChanged ? currentState.displayName : initialMetadata.displayName,
        about: aboutChanged ? currentState.about : initialMetadata.about,
        picture: profilePictureUrl ?? initialMetadata.picture,
        banner: initialMetadata.banner,
        website: initialMetadata.website,
        nip05: nip05Changed ? currentState.nip05 : initialMetadata.nip05,
        lud06: initialMetadata.lud06,
        lud16: initialMetadata.lud16,
        custom: initialMetadata.custom,
      );

      await activeAccountNotifier.updateMetadata(metadata: newMetadata);
      await fetchProfileData();
    } catch (e, st) {
      _logger.severe('updateProfileData', e, st);
      final prev = state.asData?.value ?? const ProfileState();
      final message = e is ApiError ? (await e.messageText()) : e.toString();
      state = AsyncValue.data(prev.copyWith(isSaving: false, error: message, stackTrace: st));
    }
  }
}

final editProfileScreenProvider = AsyncNotifierProvider<EditProfileScreenNotifier, ProfileState>(
  EditProfileScreenNotifier.new,
);
