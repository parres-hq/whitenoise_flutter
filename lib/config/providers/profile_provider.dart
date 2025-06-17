import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/src/rust/api.dart';

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<ProfileState> build() async {
    return const ProfileState();
  }

  Future<void> fetchProfileData() async {
    state = const AsyncValue.loading();

    try {
      final authState = ref.read(authProvider);
      if (authState.whitenoise == null || !authState.isAuthenticated) {
        state = AsyncValue.error(
          'Not authenticated or Whitenoise not initialized',
          StackTrace.current,
        );
        return;
      }

      final account =
          await ref.read(authProvider.notifier).getCurrentActiveAccount();

      if (account == null) {
        state = AsyncValue.error('No active account found', StackTrace.current);
        return;
      }

      final npub = await exportAccountNpub(
        whitenoise: authState.whitenoise!,
        account: account,
      );

      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final metadata = await fetchMetadata(
        whitenoise: authState.whitenoise!,
        pubkey: publicKey,
      );

      final metadataData = await convertMetadataToData(metadata: metadata);

      final profileState = ProfileState(
        name: metadataData?.name,
        displayName: metadataData?.displayName,
        about: metadataData?.about,
        picture: metadataData?.picture,
        banner: metadataData?.banner,
        website: null, // TODO: update metadataData to include website
        nip05: metadataData?.nip05,
        lud16: metadataData?.lud16,
        npub: npub,
      );

      state = AsyncValue.data(profileState);
    } catch (e, st) {
      debugPrintStack(label: 'ProfileNotifier.loadProfileData', stackTrace: st);
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<String?> pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e, st) {
      debugPrintStack(
        label: 'ProfileNotifier.pickProfileImage',
        stackTrace: st,
      );
      return null;
    }
  }

  Future<String?> pickBannerImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e, st) {
      debugPrintStack(label: 'ProfileNotifier.pickBannerImage', stackTrace: st);
      return null;
    }
  }

  Future<void> updateProfileData({
    String? name,
    String? displayName,
    String? about,
    String? picture,
    String? banner,
    String? nip05,
    String? lud16,
  }) async {
    try {
      state = const AsyncValue.loading();
      //TODO: refine - use state object
      final authState = ref.read(authProvider);
      if (authState.whitenoise == null || !authState.isAuthenticated) {
        state = AsyncValue.error('Not authenticated', StackTrace.current);
        return;
      }

      final account =
          await ref.read(authProvider.notifier).getCurrentActiveAccount();
      if (account == null) {
        state = AsyncValue.error('No active account found', StackTrace.current);
        return;
      }

      final npub = await exportAccountNpub(
        whitenoise: authState.whitenoise!,
        account: account,
      );
      final publicKey = await publicKeyFromString(publicKeyString: npub);
      final currentMetadata = await fetchMetadata(
        whitenoise: authState.whitenoise!,
        pubkey: publicKey,
      );

      if (currentMetadata != null) {
        final currentData = await convertMetadataToData(
          metadata: currentMetadata,
        );

        final updatedData = MetadataData(
          name: name ?? currentData?.name,
          displayName: displayName ?? currentData?.displayName,
          about: about ?? currentData?.about,
          picture: picture ?? currentData?.picture,
          banner: banner ?? currentData?.banner,
          nip05: nip05 ?? currentData?.nip05,
          lud16: lud16 ?? currentData?.lud16,
        );
        //TODO: impl helper for this
        await updateMetadata(
          whitenoise: authState.whitenoise!,
          metadata: currentMetadata,
          account: account,
        );

        await fetchProfileData();

        state = AsyncValue.data(
          ProfileState(
            name: updatedData.name,
            displayName: updatedData.displayName,
            about: updatedData.about,
            picture: updatedData.picture,
            banner: updatedData.banner,
            //TODO: website field is not in MetadataData, so we keep the current value
            website: state.value?.website,
            nip05: updatedData.nip05,
            lud16: updatedData.lud16,
            npub: npub,
          ),
        );
      } else {
        state = AsyncValue.error(
          'Failed to get current metadata',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      debugPrintStack(
        label: 'ProfileNotifier.updateProfileData',
        stackTrace: st,
      );
      state = AsyncValue.error(e.toString(), st);
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
