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

      final account = await ref.read(authProvider.notifier).getCurrentActiveAccount();

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

      final profileState = ProfileState(
        name: metadata?.name,
        displayName: metadata?.displayName,
        about: metadata?.about,
        picture: metadata?.picture,
        banner: metadata?.banner,
        website: metadata?.website,
        nip05: metadata?.nip05,
        lud16: metadata?.lud16,
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

      final account = await ref.read(authProvider.notifier).getCurrentActiveAccount();
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

      metadata?.name = name;
      metadata?.displayName = displayName;
      metadata?.about = about;
      metadata?.picture = picture;
      metadata?.banner = banner;
      metadata?.nip05 = nip05;
      metadata?.lud16 = lud16;

      final updatedData = metadata!;

      await updateMetadata(
        whitenoise: authState.whitenoise!,
        metadata: updatedData,
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
          website: state.value?.website,
          nip05: updatedData.nip05,
          lud16: updatedData.lud16,
          npub: npub,
        ),
      );
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
