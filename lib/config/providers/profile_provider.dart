import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/active_account_data_provider.dart';
import 'package:whitenoise/config/providers/auth_provider.dart';
import 'package:whitenoise/config/providers/metadata_cache_provider.dart';
import 'package:whitenoise/config/states/profile_state.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/src/rust/api.dart';
import 'package:whitenoise/src/rust/api/accounts.dart';
import 'package:whitenoise/src/rust/api/relays.dart';
import 'package:whitenoise/src/rust/api/utils.dart';
import 'package:whitenoise/src/rust/api/error.dart' show ApiError;

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

      // Get active account data from the new provider
      final activeAccountDataAsync = ref.read(activeAccountDataProvider);
      final activeAccountData = activeAccountDataAsync.valueOrNull;
      if (activeAccountData == null) {
        state = AsyncValue.error('No active account found', StackTrace.current);
        return;
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      
      // Get relays for this account separately
      final nip65RelayType = await relayTypeNip65();
      final relays = await accountRelays(
        pubkey: activeAccountData.pubkey,
        relayType: nip65RelayType,
      );
      
      final metadata = await fetchMetadataFrom(
        pubkey: publicKey,
        nip65Relays: relays,
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

      // Get active account data from the new provider
      final activeAccountDataAsync = ref.read(activeAccountDataProvider);
      final activeAccountData = activeAccountDataAsync.valueOrNull;
      if (activeAccountData == null) {
        state = AsyncValue.error('No active account found', StackTrace.current);
        return;
      }

      if ((state.value?.selectedImagePath?.isNotEmpty) ?? false) {
        final fileExtension = path.extension(state.value!.selectedImagePath!);
        final imageType = await imageTypeFromExtension(extension_: fileExtension);

        final serverUrl = await getDefaultBlossomServerUrl();
        final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);

        profilePictureUrl = await uploadProfilePicture(
          pubkey: publicKey,
          serverUrl: serverUrl,
          filePath: state.value!.selectedImagePath!,
          imageType: imageType,
        );
      }

      final publicKey = await publicKeyFromString(publicKeyString: activeAccountData.pubkey);
      
      // Get relays for this account separately
      final nip65RelayType = await relayTypeNip65();
      final relays = await accountRelays(
        pubkey: activeAccountData.pubkey,
        relayType: nip65RelayType,
      );
      
      final metadata = await fetchMetadataFrom(
        pubkey: publicKey,
        nip65Relays: relays,
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

      // Update the metadata cache with the new profile data
      await _updateMetadataCache(activeAccountData.pubkey, metadata);

      await fetchProfileData();
    } catch (e, st) {
      _logger.severe('updateProfileData', e, st);
      state = AsyncValue.data(
        state.value!.copyWith(isSaving: false, error: e, stackTrace: st),
      );

      // Handle error messaging
      String? errorMessage;
      if (e is ApiError) {
        errorMessage = await e.messageText();
      } else {
        errorMessage = e.toString();
      }
      state = AsyncValue.error(errorMessage, st);
    }
  }

  /// Update the metadata cache with new profile data
  Future<void> _updateMetadataCache(String pubkey, MetadataData metadata) async {
    try {
      // Convert pubkey to npub format for consistent caching
      final npub = await npubFromHexPubkey(hexPubkey: pubkey);

      // Create a ContactModel from the updated metadata
      final contactModel = ContactModel.fromMetadata(
        publicKey: npub,
        metadata: metadata,
      );

      // Update the metadata cache
      ref.read(metadataCacheProvider.notifier).updateCachedMetadata(npub, contactModel);

      _logger.info('Updated metadata cache for user: $npub');
    } catch (e, _) {
      _logger.warning('Failed to update metadata cache: $e');
      // Don't throw - this is not critical for the profile update
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
