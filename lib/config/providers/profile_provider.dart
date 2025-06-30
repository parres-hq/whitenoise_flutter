import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/src/rust/api.dart';

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  final _logger = Logger('ProfileNotifier');
  final ImagePicker _imagePicker = ImagePicker();

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
      );

      state = AsyncValue.data(profileState);
    } catch (e, st) {
      _logger.severe('loadProfileData', e, st);
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
      _logger.severe('pickProfileImage', e, st);
      return null;
    }
  }

  Future<void> updateProfileData({
    String? displayName,
    String? about,
    String? picture,
    String? nip05,
  }) async {
    try {
      state = const AsyncValue.loading();
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

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      final metadata = await fetchMetadata(
        pubkey: publicKey,
      );

      metadata?.displayName = displayName;
      metadata?.about = about;
      metadata?.picture = picture;
      metadata?.nip05 = nip05;

      // Create a new PublicKey object just before using it to avoid disposal issues
      final publicKeyForUpdate = await publicKeyFromString(
        publicKeyString: activeAccountData.pubkey,
      );
      await updateMetadata(
        pubkey: publicKeyForUpdate,
        metadata: metadata!,
      );

      state = AsyncValue.data(
        state.value!.copyWith(
          displayName: displayName,
          about: about,
          picture: picture,
          nip05: nip05,
        ),
      );
    } catch (e, st) {
      _logger.severe('updateProfileData', e, st);
      state = AsyncValue.error(e.toString(), st);
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
