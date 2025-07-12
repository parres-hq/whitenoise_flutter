import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  final _logger = Logger('ProfileNotifier');

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

      // Get active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = AsyncValue.error('No active account found', StackTrace.current);
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final metadata = await fetchMetadata(
        pubkey: publicKey,
      );

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
      state = AsyncValue.data(
        state.value!.copyWith(isSaving: false, stackTrace: null, error: null),
      );
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
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        state.whenData(
          (value) =>
              state = AsyncValue.data(
                value.copyWith(selectedImagePath: image.path),
              ),
        );
      }
    } catch (e, st) {
      _logger.severe('pickProfileImage', e, st);
      state = AsyncValue.error('Failed to pick profile image', st);
    }
  }

  Future<void> updateProfileData() async {
    state = AsyncValue.data(
      state.value!.copyWith(isSaving: true, error: null, stackTrace: null),
    );
    try {
      String? profilePictureUrl;
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return;
      }

      // Get active account data directly
      final activeAccountData =
          await ref.read(activeAccountProvider.notifier).getActiveAccountData();
      if (activeAccountData == null) {
        state = AsyncValue.error('No active account found', StackTrace.current);
        return;
      }

      if ((state.value?.selectedImagePath?.isNotEmpty) ?? false) {
        final fileExtension = path.extension(state.value!.selectedImagePath!);
        final imageType = await imageTypeFromExtension(extension_: fileExtension);

        final activeAccount = await ref.read(activeAccountProvider.notifier).getActiveAccountData();
        if (activeAccount == null) {
          state = AsyncValue.error('No active account found', StackTrace.current);
          return;
        }

        final serverUrl = await getDefaultBlossomServerUrl();
        final publicKey = await publicKeyFromString(publicKeyString: activeAccount.pubkey);

        profilePictureUrl = await uploadProfilePicture(
          pubkey: publicKey,
          serverUrl: serverUrl,
          filePath: state.value!.selectedImagePath!,
          imageType: imageType,
        );
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final metadata = await fetchMetadata(
        pubkey: publicKey,
      );

      if (metadata == null) {
        throw Exception('Metadata not found');
      }
      
      final currentState = state.value!;
      metadata.displayName = currentState.displayName;
      metadata.about = currentState.about;
      metadata.picture = profilePictureUrl ?? currentState.picture;
      metadata.nip05 = currentState.nip05;

      // Create a new PublicKey object just before using it to avoid disposal issues
      final publicKeyForUpdate = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );

      await updateMetadata(
        pubkey: publicKeyForUpdate,
        metadata: metadata,
      );

      await fetchProfileData();
    } catch (e, st) {
      _logger.severe('updateProfileData', e, st);
      state = AsyncValue.data(
        state.value!.copyWith(isSaving: false, error: e, stackTrace: st),
      );
      
      // Handle error messaging
      String? errorMessage;
      if (e is WhitenoiseError) {
        try {
          errorMessage = await whitenoiseErrorToString(error: e);
        } catch (conversionError) {
          errorMessage = 'Failed to update profile due to an internal error';
        }
      } else {
        errorMessage = e.toString();
      }
      state = AsyncValue.error(errorMessage, st);
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
