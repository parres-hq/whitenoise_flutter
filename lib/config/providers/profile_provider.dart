import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_account_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/utils.dart';

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

      // Create npub from pubkey for display
      final npub = activeAccountData.pubkey; // We'll use the pubkey directly for now

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
      _logger.severe('pickBannerImage', e, st);
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

      metadata?.name = name;
      metadata?.displayName = displayName;
      metadata?.about = about;
      metadata?.picture = picture;
      metadata?.banner = banner;
      metadata?.nip05 = nip05;
      metadata?.lud16 = lud16;

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
          name: name,
          displayName: displayName,
          about: about,
          picture: picture,
          banner: banner,
          nip05: nip05,
          lud16: lud16,
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
